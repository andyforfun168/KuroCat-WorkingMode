import Foundation
precondition(UpdateChecker.newer("v1.10.0",than:"1.9.9"))
precondition(UpdateChecker.newer("2.0.0",than:"1.99.99"))
precondition(!UpdateChecker.newer("v1.3.1",than:"1.3.1"))
precondition(!UpdateChecker.newer("1.3.0",than:"1.3.1"))
for value in ["","v","1.2","1.2.3.4","1.2.-1","1.2.3-beta","01.x.3","999999999999.1.1","1..3","1.2.3/../../x"] {
 precondition(UpdateChecker.version(value)==nil,"Accepted invalid update tag: \(value)")
}
print("PASS: Swift version ordering and malformed release tags")

func data(_ s:String)->Data {Data(s.utf8)}
precondition(UpdateChecker.stableTag(data("{\"draft\":false,\"prerelease\":false,\"tag_name\":\"v1.10.0\"}")) == "v1.10.0")
for json in ["{}","{not json}","{\"draft\":true,\"prerelease\":false,\"tag_name\":\"v9.0.0\"}","{\"draft\":false,\"prerelease\":true,\"tag_name\":\"v9.0.0\"}","{\"draft\":false,\"prerelease\":false,\"tag_name\":\"v9.0.0-beta\"}"] {precondition(UpdateChecker.stableTag(data(json)) == nil)}
precondition(UpdateChecker.stableTag(Data(repeating:0,count:262145)) == nil)
print("PASS: Swift stable-release JSON, API errors and oversized replies")
