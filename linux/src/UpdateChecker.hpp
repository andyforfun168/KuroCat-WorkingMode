#pragma once
#include <gio/gio.h>
#include <string>
#include "../../shared/UpdateVersion.hpp"
namespace KuroLinuxUpdate {
inline bool busy=false;
inline std::string preferences(){return CatSettings::configPath()+"/updates.ini";}
inline GKeyFile* load(){auto* key=g_key_file_new();g_key_file_load_from_file(key,preferences().c_str(),G_KEY_FILE_NONE,nullptr);return key;}
inline void save(GKeyFile* key){g_mkdir_with_parents(CatSettings::configPath().c_str(),0700);gsize length=0;gchar* data=g_key_file_to_data(key,&length,nullptr);if(data){g_file_set_contents(preferences().c_str(),data,length,nullptr);g_free(data);}}
inline bool automatic(){auto* key=load();bool value=!g_key_file_has_key(key,"updates","automatic",nullptr)||g_key_file_get_boolean(key,"updates","automatic",nullptr);g_key_file_unref(key);return value;}
inline void toggle(){bool value=!automatic();auto* key=load();g_key_file_set_boolean(key,"updates","automatic",value);save(key);g_key_file_unref(key);}
inline void show(const std::string& title,const std::string& message,bool download){
    auto* dialog=gtk_message_dialog_new(nullptr,GTK_DIALOG_MODAL,GTK_MESSAGE_INFO,GTK_BUTTONS_NONE,"%s",title.c_str());
    gtk_message_dialog_format_secondary_text(GTK_MESSAGE_DIALOG(dialog),"%s",message.c_str());
    if(download)gtk_dialog_add_button(GTK_DIALOG(dialog),"打开下载页面",GTK_RESPONSE_YES);
    gtk_dialog_add_button(GTK_DIALOG(dialog),download?"稍后":"好",GTK_RESPONSE_CLOSE);
    g_signal_connect(dialog,"response",G_CALLBACK(+[](GtkDialog* dialog,gint response,gpointer){
        if(response==GTK_RESPONSE_YES)g_app_info_launch_default_for_uri(KuroUpdate::ReleasePage,nullptr,nullptr);
        gtk_widget_destroy(GTK_WIDGET(dialog));
    }),nullptr);gtk_widget_show_all(dialog);
}
inline std::string fetch(){
    GSocketClient* client=g_socket_client_new();g_socket_client_set_timeout(client,10);g_socket_client_set_tls(client,TRUE);
    GSocketConnection* connection=g_socket_client_connect_to_host(client,"api.github.com",443,nullptr,nullptr);g_object_unref(client);
    if(!connection)return {};
    std::string request="GET /repos/"+std::string(KuroUpdate::Repository)+"/releases/latest HTTP/1.0\r\nHost: api.github.com\r\nUser-Agent: KuroCat/"+KuroUpdate::CurrentVersion+"\r\nAccept: application/vnd.github+json\r\nConnection: close\r\n\r\n";
    auto* output=g_io_stream_get_output_stream(G_IO_STREAM(connection));gsize written=0;
    bool ok=g_output_stream_write_all(output,request.data(),request.size(),&written,nullptr,nullptr);
    std::string response;char buffer[4096];auto* input=g_io_stream_get_input_stream(G_IO_STREAM(connection));
    while(ok){gssize count=g_input_stream_read(input,buffer,sizeof(buffer),nullptr,nullptr);if(count<0){ok=false;break;}if(count==0)break;response.append(buffer,(size_t)count);if(response.size()>262144){ok=false;break;}}
    g_io_stream_close(G_IO_STREAM(connection),nullptr,nullptr);g_object_unref(connection);
    if(!ok || (response.rfind("HTTP/1.1 200",0)!=0 && response.rfind("HTTP/1.0 200",0)!=0))return {};
    auto split=response.find("\r\n\r\n");if(split==std::string::npos)return {};
    return KuroUpdate::stableTag(response.substr(split+4));
}
inline void check(bool manual){
    if(busy||(!manual&&!automatic()))return;
    auto* key=load();gint64 now=g_get_real_time()/G_USEC_PER_SEC,last=g_key_file_get_int64(key,"updates","lastCheck",nullptr);
    if(!manual&&now>=last&&now-last<86400){g_key_file_unref(key);return;}
    busy=true;g_key_file_set_int64(key,"updates","lastCheck",now);save(key);g_key_file_unref(key);
    GTask* task=g_task_new(nullptr,nullptr,+[](GObject*,GAsyncResult* result,gpointer data){
        busy=false;bool manual=GPOINTER_TO_INT(data)!=0;
        gchar* raw=(gchar*)g_task_propagate_pointer(G_TASK(result),nullptr);std::string tag=raw?raw:"";g_free(raw);
        if(!manual&&!automatic())return;
        if(tag.empty()){if(manual)show("暂时无法检查更新","请稍后重试，或打开 GitHub Release 查看。",true);return;}
        if(KuroUpdate::newer(tag)){
            auto* key=load();gchar* raw=g_key_file_get_string(key,"updates","notifiedTag",nullptr);std::string old=raw?raw:"";g_free(raw);
            if(manual||old!=tag){g_key_file_set_string(key,"updates","notifiedTag",tag.c_str());save(key);show("KuroCat 有新版本 "+tag,"当前版本 "+std::string(KuroUpdate::CurrentVersion)+"。请退出旧版后下载并替换；原有设置会保留。",true);}
            g_key_file_unref(key);
        }else if(manual)show("未发现更新","当前版本 "+std::string(KuroUpdate::CurrentVersion)+"。",false);
    },GINT_TO_POINTER(manual));
    g_task_run_in_thread(task,+[](GTask* task,gpointer,gpointer,GCancellable*){std::string tag;try{tag=fetch();}catch(...){ }g_task_return_pointer(task,g_strdup(tag.c_str()),g_free);});g_object_unref(task);
}
}
