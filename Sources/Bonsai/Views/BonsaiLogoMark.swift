import SwiftUI

struct BonsaiLogoMark: View {
  var color: Color = .secondary

  var body: some View {
    Canvas { context, size in
      let scale = min(size.width / 512, size.height / 512)
      let xOffset = (size.width - 512 * scale) / 2
      let yOffset = (size.height - 512 * scale) / 2

      context.translateBy(x: xOffset, y: yOffset)
      context.scaleBy(x: scale, y: scale)

      let stroke = StrokeStyle(lineWidth: 24, lineCap: .round, lineJoin: .round)
      context.stroke(topologyPath, with: .color(color), style: stroke)
      context.stroke(nodePath, with: .color(color), style: stroke)
    }
  }

  private var topologyPath: Path {
    var path = Path()
    path.move(to: CGPoint(x: 151, y: 210))
    path.addLine(to: CGPoint(x: 151, y: 238))
    path.addCurve(
      to: CGPoint(x: 183, y: 296),
      control1: CGPoint(x: 151, y: 262),
      control2: CGPoint(x: 163, y: 283)
    )
    path.addLine(to: CGPoint(x: 231, y: 327))
    path.addCurve(
      to: CGPoint(x: 256, y: 350),
      control1: CGPoint(x: 247, y: 337),
      control2: CGPoint(x: 256, y: 342)
    )

    path.move(to: CGPoint(x: 256, y: 210))
    path.addLine(to: CGPoint(x: 256, y: 352))

    path.move(to: CGPoint(x: 361, y: 210))
    path.addLine(to: CGPoint(x: 361, y: 236))
    path.addCurve(
      to: CGPoint(x: 327, y: 297),
      control1: CGPoint(x: 361, y: 261),
      control2: CGPoint(x: 348, y: 284)
    )
    path.addLine(to: CGPoint(x: 280, y: 327))
    path.addCurve(
      to: CGPoint(x: 256, y: 350),
      control1: CGPoint(x: 265, y: 337),
      control2: CGPoint(x: 256, y: 342)
    )

    path.move(to: CGPoint(x: 256, y: 276))
    path.addCurve(
      to: CGPoint(x: 329, y: 249),
      control1: CGPoint(x: 274, y: 252),
      control2: CGPoint(x: 305, y: 256)
    )
    path.addCurve(
      to: CGPoint(x: 361, y: 218),
      control1: CGPoint(x: 346, y: 244),
      control2: CGPoint(x: 358, y: 236)
    )
    return path
  }

  private var nodePath: Path {
    var path = Path()
    path.addEllipse(in: CGRect(x: 119, y: 134, width: 64, height: 64))
    path.addEllipse(in: CGRect(x: 224, y: 134, width: 64, height: 64))
    path.addEllipse(in: CGRect(x: 329, y: 134, width: 64, height: 64))
    path.addEllipse(in: CGRect(x: 224, y: 364, width: 64, height: 64))
    return path
  }
}
