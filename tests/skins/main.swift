import AppKit
import CoreGraphics
final class RenderSettings {
 static let shared = RenderSettings()
 var coatTheme = CatCoatTheme.classicBlack
 var eyeTheme = EyeColorTheme.neonChartreuse
 var keyboardTheme = KeyboardTheme.classicMilk
 let showKeyBadges = false
}
let output = URL(fileURLWithPath: CommandLine.arguments[1])
try! FileManager.default.createDirectory(at:output,withIntermediateDirectories:true)
func frame(_ coat: CatCoatTheme,_ eye:EyeColorTheme,_ state:Int,_ legacy:Bool = false)->CGContext {
 let p=CatPhysics()
 switch state {
 case 1: p.headYaw.value = -1; p.headPitch.value = -0.65; p.headTilt.value = -0.13
 case 2: p.headYaw.value = 1; p.headPitch.value = 0.65; p.headTilt.value = 0.13
 case 3:
  p.leftPaw.x.value=78;p.leftPaw.y.value=252;p.leftPawOnMouse=true
  p.rightPaw.x.value=240;p.rightPaw.y.value=268;p.rightPawTyping=true
  p.hindFootActive.value=1;p.hindFoot.x.value=164;p.hindFoot.y.value=270
  p.bodyTilt.value=0.12;p.bodySquash.value=0.90;p.tailPhase=2
 case 4:p.sleepiness=1;p.earFold.value=0.25
 case 5:p.petHeadIntensity=0.8;p.earFold.value=0.6
 case 6:p.petBodyIntensity=0.8
 case 7:p.huntIntensity.value=1;p.pupilScale.value=1.12;p.eyeGaze.x.value=0.7;p.eyeGaze.y.value = -0.4
 default:break
 }
 let s=RenderSettings.shared;s.coatTheme=coat;s.eyeTheme=eye
 let ctx=CGContext(data:nil,width:720,height:640,bitsPerComponent:8,bytesPerRow:720*4,space:CGColorSpaceCreateDeviceRGB(),bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue)!
 ctx.translateBy(x:0,y:640);ctx.scaleBy(x:2,y:-2)
 if legacy {LegacyRenderer.draw(in:ctx,physics:p,showPermissionPill:false)} else {CurrentRenderer.draw(in:ctx,physics:p,showPermissionPill:false)}
 return ctx
}
func pixels(_ c:CGContext)->[UInt8] {Array(UnsafeBufferPointer(start:c.data!.assumingMemoryBound(to:UInt8.self),count:720*640*4))}
func save(_ c:CGContext,_ name:String){let rep=NSBitmapImageRep(cgImage:c.makeImage()!);try! rep.representation(using:.png,properties:[:])!.write(to:output.appendingPathComponent(name))}
var n=0
for coat in [CatCoatTheme.classicBlack,.siamese] {
 for eye in [EyeColorTheme.neonChartreuse,.siameseBlue,.warmAmber,.iceCyan] {
  for state in 0..<8 {precondition(pixels(frame(coat,eye,state)) == pixels(frame(coat,eye,state,true)),"Existing skin appearance changed: \(coat), \(eye), \(state)");n+=1}
 }
}
for (name,coat) in [("shorthair",CatCoatTheme.shorthair),("orangeWhite",.orangeWhite)] {
 for state in 0..<8 {
  let c=frame(coat,.referenceHazel,state)
  precondition(pixels(c).filter{$0 != 0}.count>10000,"Empty action render")
  save(c,"\(name)-\(state).png")
 }
}
for (name,coat) in [("black",CatCoatTheme.classicBlack),("siamese",.siamese)] {save(frame(coat,coat == .siamese ? .siameseBlue : .neonChartreuse,0),name+".png")}
save(frame(.shorthair,.softAmber,0),"shorthair-amber.png")
print("PASS: \(n) legacy skin/eye/action frames pixel-identical to v1.2.1; rendered 16 new skin/action frames including turned heads, typing/mouse/third paw, sleep, petting and hunting.")
