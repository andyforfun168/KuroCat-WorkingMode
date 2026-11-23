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
func frame(_ coat: CatCoatTheme,_ eye:EyeColorTheme,_ state:Int,_ legacy:Bool = false,_ pose:Int = 0,_ occludedMuzzle:Bool = false,_ pointyChin:Bool = false)->CGContext {
 let p=CatPhysics()
 switch state {
 case 1: p.headYaw.value = -1; p.headPitch.value = -0.65; p.headTilt.value = -0.13
 case 2: p.headYaw.value = 1; p.headPitch.value = 0.65; p.headTilt.value = 0.13
 case 3:
  p.leftPaw.x.value=78;p.leftPaw.y.value=252;p.leftPawOnMouse=true
  p.rightPaw.x.value=240;p.rightPaw.y.value=268;p.rightPawTyping=true
  p.hindFootActive.value=1;p.hindFoot.x.value=164;p.hindFoot.y.value=270
  p.bodyTilt.value=0.12;p.bodySquash.value=0.90;p.tailPhase=2
 case 8,9:
  p.headYaw.value = -0.65;p.headPitch.value = 0.2;p.headTilt.value = -0.08
  if pose > 0 {
   p.headYaw.value = pose % 2 == 0 ? -1 : 1
   p.headPitch.value = pose % 4 < 2 ? -1 : 1
   p.headTilt.value = pose % 2 == 0 ? -0.18 : 0.18
   p.bodyTilt.value = pose % 2 == 0 ? -0.15 : 0.15
   p.bodySquash.value = pose % 4 < 2 ? 0.85 : 1.08
   p.headOffsetY.value = 14
  }
  if state == 8 {
   p.leftPaw.x.value=78;p.leftPaw.y.value=252;p.leftPawOnMouse=true
   if pose > 3 {p.rightPaw.x.value=240;p.rightPaw.y.value=262;p.rightPawTyping=true}
  }
 case 4:p.sleepiness=1;p.earFold.value=0.25
 case 5:p.petHeadIntensity=0.8;p.earFold.value=0.6
 case 6:p.petBodyIntensity=0.8
 case 7:p.huntIntensity.value=1;p.pupilScale.value=1.12;p.eyeGaze.x.value=0.7;p.eyeGaze.y.value = -0.4
 default:break
 }
 let s=RenderSettings.shared;s.coatTheme=coat;s.eyeTheme=eye
 let ctx=CGContext(data:nil,width:720,height:640,bitsPerComponent:8,bytesPerRow:720*4,space:CGColorSpaceCreateDeviceRGB(),bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue)!
 ctx.translateBy(x:0,y:640);ctx.scaleBy(x:2,y:-2)
 if pointyChin {PointyChinRenderer.draw(in:ctx,physics:p,showPermissionPill:false)} else if occludedMuzzle {OccludedMuzzleRenderer.draw(in:ctx,physics:p,showPermissionPill:false)} else if legacy {LegacyRenderer.draw(in:ctx,physics:p,showPermissionPill:false)} else {CurrentRenderer.draw(in:ctx,physics:p,showPermissionPill:false)}
 return ctx
}
func pixels(_ c:CGContext)->[UInt8] {Array(UnsafeBufferPointer(start:c.data!.assumingMemoryBound(to:UInt8.self),count:720*640*4))}
func save(_ c:CGContext,_ name:String){let rep=NSBitmapImageRep(cgImage:c.makeImage()!);try! rep.representation(using:.png,properties:[:])!.write(to:output.appendingPathComponent(name))}
var n=0
for coat in [CatCoatTheme.classicBlack,.siamese] {
 for eye in [EyeColorTheme.neonChartreuse,.siameseBlue,.warmAmber,.iceCyan] {
  for state in [0,1,2,4,5,6,7] {precondition(pixels(frame(coat,eye,state)) == pixels(frame(coat,eye,state,true)),"Existing skin appearance changed: \(coat), \(eye), \(state)");n+=1}
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
print("PASS: \(n) legacy skin/eye/action frames pixel-identical to v1.3.0; rendered 16 new skin/action frames including turned heads, typing/mouse/third paw, sleep, petting and hunting.")

for (name,coat) in [("shorthair",CatCoatTheme.shorthair),("orangeWhite",.orangeWhite)] {
 save(frame(coat,.softAmber,8),name+"-shoulder-after.png")
 save(frame(coat,.softAmber,8,true),name+"-shoulder-before.png")
}

var oldFaceChanges = 0
for coat in CatCoatTheme.allCases {
 let active = pixels(frame(coat,.softAmber,8)), idle = pixels(frame(coat,.softAmber,9))
 let oldActive = pixels(frame(coat,.softAmber,8,true)), oldIdle = pixels(frame(coat,.softAmber,9,true))
 for y in 160..<342 {
  for x in 240..<490 {
   let i=(y*720+x)*4
   precondition(Array(active[i..<i+4]) == Array(idle[i..<i+4]),"Reaching arm changes face pixels: \(coat)")
   if Array(oldActive[i..<i+4]) != Array(oldIdle[i..<i+4]) {oldFaceChanges += 1}
  }
 }
}
precondition(oldFaceChanges > 0,"Shoulder fixture did not reproduce the old intrusion")
print("PASS: reaching arms leave the face unchanged across all four skins; old fixture contaminated \(oldFaceChanges) pixels")

for coat in CatCoatTheme.allCases {
 for pose in 1...8 {
  let active=pixels(frame(coat,.referenceHazel,8,false,pose)),idle=pixels(frame(coat,.referenceHazel,9,false,pose))
  let yaw:CGFloat=pose % 2 == 0 ? -1 : 1, tilt:CGFloat=pose % 2 == 0 ? -0.15 : 0.15
  let pitch:CGFloat=pose % 4 < 2 ? -1 : 1
  let cx=184+tilt*36+yaw*7.5,cy=126+14+pitch*4.8
  for y in Int((cy-35)*2)..<Int((cy+40)*2) {
   for x in Int((cx-52)*2)..<Int((cx+52)*2) {
    let i=(y*720+x)*4
    precondition(Array(active[i..<i+4]) == Array(idle[i..<i+4]),"Arm intrudes on turned face: \(coat), pose \(pose)")
   }
  }
 }
}
print("PASS: 32 extreme turn/tilt/squash poses preserve face pixels during mouse and typing actions")

precondition(EyeColorTheme.saved("淡金青绿（参考图）") == .referenceHazel)
for eye in EyeColorTheme.allCases {precondition(EyeColorTheme.saved(eye.rawValue) == eye)}
print("PASS: renamed hazel theme restores both old and current saved settings")

let swatch=CGContext(data:nil,width:1,height:1,bitsPerComponent:8,bytesPerRow:4,space:CGColorSpaceCreateDeviceRGB(),bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue)!
swatch.setFillColor(NSColor(calibratedRed:216.0/255,green:170.0/255,blue:115.0/255,alpha:1).cgColor)
swatch.fill(CGRect(x:0,y:0,width:1,height:1))
let ginger=Array(UnsafeBufferPointer(start:swatch.data!.assumingMemoryBound(to:UInt8.self),count:4))
for pose in 1...8 {
 let buffer=pixels(frame(.orangeWhite,.referenceHazel,9,false,pose))
 let yaw:CGFloat=pose % 2 == 0 ? -1 : 1,tilt:CGFloat=pose % 2 == 0 ? -0.15 : 0.15
 let pitch:CGFloat=pose % 4 < 2 ? -1 : 1,roll:CGFloat=pose % 2 == 0 ? -0.18 : 0.18
 let cx=184+tilt*36+yaw*7.5,cy=126+14+pitch*4.8
 let x = -yaw*38,y:CGFloat = -8
 let px=Int((cx+x*cos(roll)-y*sin(roll))*2),py=Int((cy+x*sin(roll)+y*cos(roll))*2)
 let offset=(py*720+px)*4
 for channel in 0..<4 {precondition(abs(Int(buffer[offset+channel])-Int(ginger[channel])) <= 2,"Orange-white rear head exposed in pose \(pose)")}
}
print("PASS: orange-white rear head remains orange through left/right, pitch and roll poses")

// Turned-down cheek intersected a body spot in v1.3.3; sample its interior, not an antialiased edge.
swatch.setFillColor(NSColor(calibratedRed:242.0/255,green:238.0/255,blue:228.0/255,alpha:1).cgColor)
swatch.fill(CGRect(x:0,y:0,width:1,height:1))
let milk=Array(UnsafeBufferPointer(start:swatch.data!.assumingMemoryBound(to:UInt8.self),count:4))
let chin=pixels(frame(.orangeWhite,.referenceHazel,2))
let coveredChin=pixels(frame(.orangeWhite,.referenceHazel,2,false,0,true))
var occludedChinPixels=0
for y in 320...322 {for x in 424...426 {
 let i=(y*720+x)*4
 for ch in 0..<4 {precondition(abs(Int(chin[i+ch])-Int(milk[ch]))<=2,"Turned chin covered by body spot")}
 if abs(Int(coveredChin[i+2])-Int(milk[2]))>30 {occludedChinPixels+=1}
}}
precondition(occludedChinPixels==9,"Muzzle fixture no longer reproduces body occlusion")
print("PASS: turned white chin stays in front of body spots; all 9 fixture pixels previously occluded")

let oldPoint=pixels(frame(.orangeWhite,.referenceHazel,2,false,0,false,true))
for (x,y) in [(434,314),(435,314),(436,314),(434,315),(435,315)] {
 let i=(y*720+x)*4
 for ch in 0..<4 {precondition(abs(Int(chin[i+ch])-Int(milk[ch]))<=2,"Orange tip leaks through opaque white chin")}
 precondition(abs(Int(oldPoint[i+2])-Int(milk[2]))>30,"Pointy chin fixture failed to reproduce orange tip")
}
print("PASS: all 5 formerly orange chin-tip pixels are now opaque white")

for coat in [CatCoatTheme.shorthair,.orangeWhite] {
 let marks=CoatPatterns.marks(for:coat)
 let firstHead=marks.firstIndex(where:{$0.head})!
 precondition(marks[firstHead...].allSatisfy{$0.head},"Body element painted above head")
 let face=marks.last!
 precondition(face.head && !face.skull && face.rgb==0xF2EEE4 && face.alpha==1 && face.width==0,"Cheek/chin must be the opaque foreground coat layer")
}
func cheekPath(_ points:[CGPoint])->CGPath {
 let p=CGMutablePath();p.addLines(between:points);p.closeSubpath();return p
}
let roundedCheek=cheekPath(CoatPatterns.shorthair.last!.points)
let flatCheek=cheekPath(PointyChinRendererPatterns.shorthair.last!.points)
precondition(roundedCheek.contains(CGPoint(x:0,y:34)),"Rounded chin lost its central arc")
precondition(!roundedCheek.contains(CGPoint(x:14,y:34)),"Shorthair lower chin still has a flat wide edge")
precondition(flatCheek.contains(CGPoint(x:14,y:34)),"Fixture did not reproduce the old wide flat chin")
print("PASS: all body marks behind head; opaque foreground cheeks; smaller rounded shorthair chin replaces flat fixture")
for coat in [CatCoatTheme.shorthair,.orangeWhite] {
 let now=CoatPatterns.marks(for:coat)
 let old=PointyChinRendererPatterns.marks(for:coat)
 let body=now.filter{!$0.head},oldBody=old.filter{!$0.head}
 precondition(body.count==oldBody.count)
 for (a,b) in zip(body,oldBody) {precondition(a.points==b.points && a.rgb==b.rgb && a.width==b.width && a.alpha==b.alpha,"Original body coat artwork changed")}
 let patterns=now.filter{$0.head && !$0.skull && $0.rgb != 0xF2EEE4}
 let oldPatterns=old.filter{$0.head && !$0.skull && $0.rgb != 0xF2EEE4}
 precondition(patterns.count==oldPatterns.count)
 for (a,b) in zip(patterns,oldPatterns) {precondition(a.points==b.points && a.rgb==b.rgb && a.width==b.width && a.alpha==b.alpha,"Original head pattern changed")}
}
print("PASS: original body spots, tabby stripes and forehead pattern geometry preserved")
