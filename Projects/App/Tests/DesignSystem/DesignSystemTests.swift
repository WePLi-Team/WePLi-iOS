import SwiftUI
import UIKit
@testable import WePLi
import XCTest

// REQ-002 · REQ-004 · REQ-005 — 토큰 값이 원본(docs/design/README.md · UI-12d)과 같은지 지킨다.

final class DesignSystemTests: XCTestCase {
  func testColorTokens_matchDesignHex() {
    XCTAssertEqual(self.hex(WePLiColor.background), 0x000000)
    XCTAssertEqual(self.hex(WePLiColor.surface1), 0x141417)
    XCTAssertEqual(self.hex(WePLiColor.textPrimary), 0xF0F0F0)
    XCTAssertEqual(self.hex(WePLiColor.accent), 0xC8CFFF)
    XCTAssertEqual(self.hex(WePLiColor.positive), 0xA4FFFF)
    XCTAssertEqual(self.hex(WePLiColor.highlight), 0xFE82DB)
    XCTAssertEqual(self.hex(WePLiColor.destructive), 0xFF453A)
    XCTAssertEqual(self.hex(WePLiColor.textOnCTA), 0x171821)
  }

  func testChromeMetrics_matchUI12d() {
    XCTAssertEqual(WePLiChrome.glass.sheetCornerRadius, 34)
    XCTAssertEqual(WePLiChrome.material.sheetCornerRadius, 10)
    XCTAssertEqual(WePLiChrome.glass.groupCornerRadius, 26)
    XCTAssertEqual(WePLiChrome.material.groupCornerRadius, 10)
    XCTAssertEqual(WePLiChrome.glass.listRowHeight, 52)
    XCTAssertEqual(WePLiChrome.material.listRowHeight, 44)
    XCTAssertEqual(WePLiChrome.glass.miniPlayerHeight, 56)
    XCTAssertEqual(WePLiChrome.material.miniPlayerHeight, 64)
  }

  func testChromeCurrent_followsOSVersion() {
    if #available(iOS 26, *) {
      XCTAssertEqual(WePLiChrome.current, .glass)
    } else {
      XCTAssertEqual(WePLiChrome.current, .material)
    }
  }

  func testFontStyles_neverBelowMinimumSize() {
    for style in WePLiFont.Style.allCases {
      XCTAssertGreaterThanOrEqual(style.size, 12, "\(style)")
    }
    XCTAssertEqual(WePLiFont.Style.body.size, 15)
    XCTAssertEqual(WePLiFont.Style.body.weight, .regular)
  }

  func testPretendard_isBundledAndRegistered() {
    WePLiFont.register()
    let weights: [WePLiFont.Weight] = [.light, .regular, .medium, .semibold, .bold]
    for weight in weights {
      XCTAssertNotNil(UIFont(name: weight.postScriptName, size: 15), weight.postScriptName)
    }
  }

  func testComponentSizes_matchDesign() {
    XCTAssertEqual(WePLiIconButton.size, 44)
    XCTAssertEqual(WePLiPrimaryButton.height, 54)
    XCTAssertEqual(WePLiToast.height, 44)
    XCTAssertEqual(WePLiToast.duration, .milliseconds(2200))
  }

  private func hex(_ color: Color) -> UInt32 {
    var red: CGFloat = 0
    var green: CGFloat = 0
    var blue: CGFloat = 0
    var alpha: CGFloat = 0
    UIColor(color).getRed(&red, green: &green, blue: &blue, alpha: &alpha)
    let channel = { (value: CGFloat) in UInt32((value * 255).rounded()) }
    return channel(red) << 16 | channel(green) << 8 | channel(blue)
  }
}
