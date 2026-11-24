import AppKit
import CoreGraphics
final class MemoryPreferences {
 var values:[String:Any]=[:]
 func set(_ value:Any?,forKey key:String){values[key]=value}
 func object(forKey key:String)->Any?{values[key]}
 func string(forKey key:String)->String?{values[key] as? String}
 func integer(forKey key:String)->Int{values[key] as? Int ?? 0}
 func double(forKey key:String)->Double{values[key] as? Double ?? 0}
}
let fixtureDefaults=MemoryPreferences()
let settings=CatSettings.shared
precondition(settings.tailEasterEgg && settings.keyboardMarquee,"New interactions must default to enabled")
let delegate=AppDelegate()
for (selector,key) in [("toggleTailEgg","KuroCat.TailEasterEgg"),("toggleKeyboardMarquee","KuroCat.KeyboardMarquee")] {
 delegate.perform(NSSelectorFromString(selector))
 precondition(fixtureDefaults.object(forKey:key) as? Bool == false,"Menu toggle did not save off")
 delegate.perform(NSSelectorFromString(selector))
 precondition(fixtureDefaults.object(forKey:key) as? Bool == true,"Menu toggle did not save on")
}
for (coat,eye) in [(CatCoatTheme.orangeWhite,EyeColorTheme.warmAmber),(.shorthair,.referenceHazel)] {
 for _ in 0..<2 {
  settings.eyeTheme = .iceCyan
  let item=NSMenuItem();item.representedObject=coat.rawValue
  delegate.perform(NSSelectorFromString("selectCoatTheme:"),with:item)
  precondition(settings.coatTheme==coat && settings.eyeTheme==eye,"Skin/eye pairing changed")
 }
}
func step(_ p:CatPhysics,_ keys:[PhysicalKey]) {
 let input=ScriptedFrameInput(now:100,activeKeys:Set(keys),orderedKeys:keys,mouseScreenPos:.zero,mouseVelocity:.zero,leftMouseDown:false,rightMouseDown:false,lastMouseMoveTime:100,lastMouseClickTime:100,lastKeyActivityTime:100)
 p.step(dt:1/60,windowFrameInScreen:CGRect(x:0,y:0,width:360,height:320),scripted:input)
}
for keys:[PhysicalKey] in [[.a,.s,.d],[.a,.s,.d,.f],[.a,.s,.d,.f,.g]] {
 let p=CatPhysics();step(p,keys)
 precondition(p.tailTyping.target == (keys.count==4 ? 1 : 0),"Tail must press only with exactly four keys")
 precondition(p.hindFootActive.target==1,"Third-key foot stopped working")
}
settings.tailEasterEgg=false
let disabled=CatPhysics();step(disabled,[.a,.s,.d,.f]);precondition(disabled.tailTyping.target==0)
settings.tailEasterEgg=true
let marquee=CatPhysics();step(marquee,[]);precondition(marquee.marqueePhase>0)
settings.keyboardMarquee=false
let stopped=marquee.marqueePhase;step(marquee,[]);precondition(marquee.marqueePhase==stopped)
func render(_ p:CatPhysics)->[UInt8] {
 let c=CGContext(data:nil,width:720,height:640,bitsPerComponent:8,bytesPerRow:2880,space:CGColorSpaceCreateDeviceRGB(),bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue)!
 c.translateBy(x:0,y:640);c.scaleBy(x:2,y:-2)
 CatRenderer.draw(in:c,physics:p,showPermissionPill:false)
 return Array(UnsafeBufferPointer(start:c.data!.assumingMemoryBound(to:UInt8.self),count:720*640*4))
}
let plain=render(marquee);settings.keyboardMarquee=true;let lit=render(marquee)
precondition(zip(plain,lit).filter{$0 != $1}.count>1000,"Marquee does not affect keyboard rendering")
settings.keyboardMarquee=false;precondition(render(marquee)==plain,"Disabling marquee does not restore static keyboard")
let hover=CatPhysics();hover.updateTailHover(canvasPoint:CGPoint(x:278,y:196))
precondition(hover.tailFlick.target != .zero,"Tail does not react to nearby cursor")
for _ in 0..<90 {step(hover,[])}
precondition(hover.tailFlick.target == .zero && hover.tailCurl.target==0,"Tail does not relax after hover")
let engine=InputEngine.shared
engine.activeKeys=[.a,.s];engine.pressedOrder=[.a,.s];engine.leftMouseDown=true
var released:Set<PhysicalKey>=[];engine.onKeyUp={released.insert($0)}
engine.resetAllKeys()
precondition(engine.activeKeys.isEmpty && engine.pressedOrder.isEmpty && !engine.leftMouseDown && released==[.a,.s],"Input reset leaves stuck keys/buttons")
print("PASS: menu defaults and persistence, paired eyes, exact-four tail, third-key foot, marquee animation/toggle/render restore, tail hover/recovery, and input reset. No real settings or input monitors touched.")
