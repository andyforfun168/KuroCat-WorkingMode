#include "../../shared/UpdateVersion.hpp"
#include <cassert>
#include <iostream>
using namespace KuroUpdate;
int main(){
 assert(newer("v1.10.0","1.9.9"));assert(newer("2.0.0","1.99.99"));
 assert(!newer("v1.3.1","1.3.1"));assert(!newer("1.3.0","1.3.1"));
 for(auto text:{"","v","1.2","1.2.3.4","1.2.-1","1.2.3-beta","01.x.3","999999999999.1.1","1..3","1.2.3/../../x"})assert(!version(text));
 assert(stableTag("{\"draft\":false,\"prerelease\":false,\"tag_name\":\"v1.10.0\"}")=="v1.10.0");
 assert(stableTag("{\"draft\":true,\"prerelease\":false,\"tag_name\":\"v2.0.0\"}").empty());
 assert(stableTag("{\"draft\":false,\"prerelease\":true,\"tag_name\":\"v2.0.0\"}").empty());
 assert(stableTag("{\"message\":\"API rate limit exceeded\"}").empty());
 assert(stableTag(std::string(262145,'x')).empty());
 std::cout<<"PASS: version ordering, invalid tags, draft/prerelease exclusion and API errors\n";
}
