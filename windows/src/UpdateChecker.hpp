#pragma once
#include <winhttp.h>
#include <atomic>
#include <ctime>
#include <memory>
#include <mutex>
#include <thread>
#include "../../shared/UpdateVersion.hpp"
#pragma comment(lib,"winhttp.lib")
namespace KuroWinUpdate {
constexpr UINT ResultMessage=WM_APP+3;
struct State {std::atomic<bool> busy{false};std::mutex mutex;std::string tag;bool manual=false,ready=false;};
inline auto state=std::make_shared<State>();
inline DWORD readNumber(const wchar_t* name,DWORD fallback){
    DWORD value=fallback,size=sizeof(value);RegGetValueW(HKEY_CURRENT_USER,L"Software\\KuroCat",name,RRF_RT_REG_DWORD,nullptr,&value,&size);return value;
}
inline void writeNumber(const wchar_t* name,DWORD value){
    HKEY key=nullptr;if(RegCreateKeyExW(HKEY_CURRENT_USER,L"Software\\KuroCat",0,nullptr,0,KEY_SET_VALUE,nullptr,&key,nullptr)==ERROR_SUCCESS){RegSetValueExW(key,name,0,REG_DWORD,(const BYTE*)&value,sizeof(value));RegCloseKey(key);}
}
inline bool automatic(){return readNumber(L"UpdateAutomatic",1)!=0;}
inline void toggle(){writeNumber(L"UpdateAutomatic",automatic()?0:1);}
inline std::string notified(){
    wchar_t value[80]={};DWORD size=sizeof(value);
    if(RegGetValueW(HKEY_CURRENT_USER,L"Software\\KuroCat",L"UpdateNotifiedTag",RRF_RT_REG_SZ,nullptr,value,&size)!=ERROR_SUCCESS)return {};
    std::wstring w(value);return std::string(w.begin(),w.end());
}
inline void mark(const std::string& tag){
    std::wstring w(tag.begin(),tag.end());HKEY key=nullptr;
    if(RegCreateKeyExW(HKEY_CURRENT_USER,L"Software\\KuroCat",0,nullptr,0,KEY_SET_VALUE,nullptr,&key,nullptr)==ERROR_SUCCESS){RegSetValueExW(key,L"UpdateNotifiedTag",0,REG_SZ,(const BYTE*)w.c_str(),(DWORD)((w.size()+1)*sizeof(wchar_t)));RegCloseKey(key);}
}
struct Internet {HINTERNET value=nullptr;~Internet(){if(value)WinHttpCloseHandle(value);}};
inline std::string fetch(){
    std::string agent="KuroCat/"+std::string(KuroUpdate::CurrentVersion);std::wstring wa(agent.begin(),agent.end());
    Internet session{WinHttpOpen(wa.c_str(),WINHTTP_ACCESS_TYPE_AUTOMATIC_PROXY,WINHTTP_NO_PROXY_NAME,WINHTTP_NO_PROXY_BYPASS,0)};if(!session.value)return {};
    WinHttpSetTimeouts(session.value,5000,5000,5000,5000);
    Internet connection{WinHttpConnect(session.value,L"api.github.com",INTERNET_DEFAULT_HTTPS_PORT,0)};if(!connection.value)return {};
    std::string path="/repos/"+std::string(KuroUpdate::Repository)+"/releases/latest";std::wstring wp(path.begin(),path.end());
    Internet request{WinHttpOpenRequest(connection.value,L"GET",wp.c_str(),nullptr,WINHTTP_NO_REFERER,WINHTTP_DEFAULT_ACCEPT_TYPES,WINHTTP_FLAG_SECURE)};if(!request.value)return {};
    if(!WinHttpSendRequest(request.value,L"Accept: application/vnd.github+json\r\n",(DWORD)-1,WINHTTP_NO_REQUEST_DATA,0,0,0)||!WinHttpReceiveResponse(request.value,nullptr))return {};
    DWORD status=0,size=sizeof(status);
    if(!WinHttpQueryHeaders(request.value,WINHTTP_QUERY_STATUS_CODE|WINHTTP_QUERY_FLAG_NUMBER,WINHTTP_HEADER_NAME_BY_INDEX,&status,&size,WINHTTP_NO_HEADER_INDEX)||status!=200)return {};
    std::string body;char buffer[4096];DWORD count=0;
    do{if(!WinHttpReadData(request.value,buffer,sizeof(buffer),&count))return {};body.append(buffer,count);if(body.size()>262144)return {};}while(count);
    return KuroUpdate::stableTag(body);
}
inline void check(HWND window,bool manual){
    auto now=(DWORD)std::time(nullptr),last=readNumber(L"UpdateLastCheck",0);
    if(!manual&&(!automatic()||(now>=last&&now-last<86400)))return;
    auto shared=state;if(shared->busy.exchange(true))return;writeNumber(L"UpdateLastCheck",now);
    std::thread([shared,window,manual]{std::string tag;try{tag=fetch();}catch(...){ }
        {std::lock_guard<std::mutex> guard(shared->mutex);shared->tag=tag;shared->manual=manual;shared->ready=true;}
        PostMessageW(window,ResultMessage,0,0);
    }).detach();
}
inline void complete(HWND window){
    std::string tag;bool manual;
    {std::lock_guard<std::mutex> guard(state->mutex);if(!state->ready)return;tag=state->tag;manual=state->manual;state->ready=false;state->busy=false;}
    if(!manual&&!automatic())return;
    if(tag.empty()){
        if(manual&&MessageBoxW(window,L"暂时无法检查更新。是否打开 GitHub Release 查看？",L"KuroCat 更新",MB_YESNO|MB_ICONINFORMATION)==IDYES)ShellExecuteA(nullptr,"open",KuroUpdate::ReleasePage,nullptr,nullptr,SW_SHOWNORMAL);
        return;
    }
    if(KuroUpdate::newer(tag)){
        if(!manual&&tag==notified())return;mark(tag);
        std::wstring w(tag.begin(),tag.end());std::wstring message=L"发现新版本 "+w+L"。请退出旧版后下载并替换程序；设置会保留。现在打开下载页面？";
        if(MessageBoxW(window,message.c_str(),L"KuroCat 有新版本",MB_YESNO|MB_ICONINFORMATION)==IDYES)ShellExecuteA(nullptr,"open",KuroUpdate::ReleasePage,nullptr,nullptr,SW_SHOWNORMAL);
    }else if(manual)MessageBoxW(window,L"未发现更新。",L"KuroCat 更新",MB_OK|MB_ICONINFORMATION);
}
}
