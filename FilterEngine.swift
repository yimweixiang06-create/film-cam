import CoreImage
import CoreImage.CIFilterBuiltins
import UIKit

enum FilterEngine {
    static func apply(_ source: CIImage, look: ImageLook) -> CIImage {
        var image = source
        let amount = look.intensity
        let point = look.point

        let exposure = CIFilter.exposureAdjust()
        exposure.inputImage = image
        exposure.ev = Float(look.exposure + (0.5 - point.y) * 0.8 * amount)
        image = exposure.outputImage ?? image

        let controls = CIFilter.colorControls()
        controls.inputImage = image
        controls.saturation = Float(1.0 + (point.x - 0.5) * 0.9 * amount)
        controls.contrast = Float(1.0 + styleContrast(look.style) * amount)
        image = controls.outputImage ?? image

        let temp = CIFilter.temperatureAndTint()
        temp.inputImage = image
        let base = styleTemperature(look.style)
        let filmShift: Float
        switch look.film {
        case .fuji400, .fujiCool: filmShift = -1100
        case .kodak800, .kodakWarm: filmShift = 1700
        case .none: filmShift = 0
        }
        temp.neutral = CIVector(x: 6500, y: 0)
        temp.targetNeutral = CIVector(x: CGFloat(6500 + base + filmShift + Float((point.x - 0.5) * 900 * amount)), y: CGFloat((point.y - 0.5) * 35))
        image = temp.outputImage ?? image

        if look.style == .monochrome {
            let mono = CIFilter.photoEffectMono()
            mono.inputImage = image
            image = mono.outputImage ?? image
        }
        if look.film != nil {
            let grain = CIFilter.randomGenerator().outputImage?.cropped(to: image.extent)
            if let grain {
                let blend = CIFilter.softLightBlendMode()
                blend.inputImage = grain
                blend.backgroundImage = image
                image = blend.outputImage ?? image
            }
            let fade = CIFilter.colorControls()
            fade.inputImage = image
            fade.saturation = look.film == .fuji400 || look.film == .fujiCool ? 0.94 : 1.05
            fade.contrast = 1.08
            image = fade.outputImage ?? image
        }
        return image
    }

    private static func styleContrast(_ style: NativeStyle) -> Double {
        switch style {
        case .standard: return 0
        case .amber, .gold, .roseGold: return 0.06
        case .neutral: return -0.04
        case .vibrant: return 0.12
        case .warm: return 0.03
        case .ethereal: return -0.08
        case .dramatic: return 0.22
        case .luminous: return 0.08
        case .monochrome: return 0.12
        }
    }

    private static func styleTemperature(_ style: NativeStyle) -> Float {
        switch style {
        case .standard, .neutral, .vibrant, .ethereal, .dramatic, .luminous, .monochrome: return 0
        case .amber: return 1200
        case .gold: return 900
        case .roseGold: return 500
        case .warm: return 650
        }
    }
}
