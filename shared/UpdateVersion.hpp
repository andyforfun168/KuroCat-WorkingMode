#pragma once
#include <array>
#include <optional>
#include <regex>
#include <string>
namespace KuroUpdate {
inline constexpr char CurrentVersion[] = "1.3.1";
inline constexpr char Repository[] = "andyforfun168/KuroCatAndy";
inline constexpr char ReleasePage[] = "https://github.com/andyforfun168/KuroCatAndy/releases/latest";
inline std::optional<std::array<int,3>> version(std::string text) {
    if (!text.empty() && text[0]=='v') text.erase(0,1);
    std::array<int,3> values{}; size_t start=0;
    for (int i=0;i<3;++i) {
        size_t end=text.find('.',start);
        if(i==2){if(end!=std::string::npos)return std::nullopt;end=text.size();}
        else if(end==std::string::npos)return std::nullopt;
        if(end==start)return std::nullopt;
        int value=0;
        for(size_t k=start;k<end;++k){
            if(text[k]<'0'||text[k]>'9'||value>100000)return std::nullopt;
            value=value*10+text[k]-'0';if(value>1000000)return std::nullopt;
        }
        values[i]=value;start=end+1;
    }
    return values;
}
inline bool newer(const std::string& remote,const std::string& current=CurrentVersion) {
    auto r=version(remote),c=version(current);return r&&c&&*r>*c;
}
inline std::string stableTag(const std::string& json) {
    if(json.size()>262144)return {};
    if(!std::regex_search(json,std::regex("\"draft\"\\s*:\\s*false")) ||
       !std::regex_search(json,std::regex("\"prerelease\"\\s*:\\s*false")))return {};
    std::smatch m;
    if(!std::regex_search(json,m,std::regex("\"tag_name\"\\s*:\\s*\"([v0-9.]+)\"")))return {};
    auto text=m[1].str();return version(text)?text:std::string();
}
}
