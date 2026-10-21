import SwiftUI

// UI-7d 다섯 상태 — 강제 업데이트(닫기 없음) · 점검 · 오프라인 · 이용 제한 · 이벤트 팝업

struct ForceUpdateScreen: View {
  let current: String
  let update: SystemConfig.Update
  let onUpdate: () -> Void

  var body: some View {
    VStack(spacing: 14) {
      Spacer()
      // 미결정 — 로고 에셋이 없어 글자로 자리 표시
      RoundedRectangle(cornerRadius: 24)
        .fill(WePLiColor.background)
        .overlay(RoundedRectangle(cornerRadius: 24).strokeBorder(Color.white.opacity(0.2), lineWidth: 0.5))
        .overlay {
          Text("W").font(.custom(WePLiFont.Weight.bold.postScriptName, size: 34, relativeTo: .title))
            .foregroundStyle(WePLiColor.accent)
        }
        .frame(width: 96, height: 96)
        .accessibilityHidden(true)
      Text("새 버전이 나왔어요").wepliFont(.title1, weight: .bold).foregroundStyle(WePLiColor.textPrimary).padding(.top, 10)
      Text("\(self.update.reason)\n업데이트 후 계속 이용할 수 있어요.")
        .wepliFont(.body)
        .foregroundStyle(WePLiColor.textSecondary)
      HStack(spacing: 8) {
        Text("현재 \(self.current)").foregroundStyle(WePLiColor.textQuaternary)
        Text("→").foregroundStyle(WePLiColor.textDisabled)
        Text("최신 \(self.update.latest)").fontWeight(.semibold).foregroundStyle(WePLiColor.positive)
      }
      .wepliFont(.subheadline)
      .padding(.top, 6)
      Spacer()
      WePLiPrimaryButton(title: "App Store에서 업데이트", action: self.onUpdate)
    }
    .multilineTextAlignment(.center)
    .padding(.horizontal, 28)
    .padding(.bottom, 24)
  }
}

struct MaintenanceScreen: View {
  let maintenance: SystemConfig.Maintenance
  let now: Date

  var body: some View {
    VStack(spacing: 14) {
      Spacer()
      Circle().fill(WePLiColor.accentStrong.opacity(0.14)).frame(width: 88, height: 88)
        .overlay {
          Image(systemName: "wrench.adjustable").font(.system(size: 34, weight: .light))
            .foregroundStyle(WePLiColor.accent)
        }
        .accessibilityHidden(true)
      Text("지금은 서버 점검 중이에요").wepliFont(.title1, weight: .bold).foregroundStyle(WePLiColor.textPrimary).padding(.top, 6)
      Text("더 안정적인 위플리를 위해 잠시 쉬어가요.").wepliFont(.body).foregroundStyle(WePLiColor.textSecondary)
      VStack(alignment: .leading, spacing: 10) {
        self.row("점검 시간", self.maintenance.window)
        self.row("남은 시간", SystemStatusText.remaining(from: self.now, to: self.maintenance.endsAt), accent: true)
        Rectangle().fill(Color.white.opacity(0.08)).frame(height: 0.5)
        Text("진행 중인 릴레이리스트의 마감 시간은 점검 시간만큼 자동으로 늘어나요.")
          .wepliFont(.footnote)
          .foregroundStyle(WePLiColor.textSecondary)
      }
      .multilineTextAlignment(.leading)
      .padding(16)
      .background(WePLiColor.surface1, in: RoundedRectangle(cornerRadius: 18))
      .padding(.top, 10)
      Spacer()
      // 미결정 — 원본 「공지 자세히 보기」는 공지(7a)로 가야 하지만, 점검 중에는 공지를 불러올 수 없어 두지 않는다
    }
    .multilineTextAlignment(.center)
    .padding(.horizontal, 28)
    .padding(.bottom, 24)
  }

  private func row(_ label: String, _ value: String, accent: Bool = false) -> some View {
    HStack {
      Text(label).foregroundStyle(WePLiColor.textQuaternary)
      Spacer()
      Text(value).monospacedDigit().foregroundStyle(accent ? WePLiColor.positive : WePLiColor.textPrimary)
    }
    .wepliFont(.subheadline)
  }
}

/// 오프라인 — 뒤 화면을 흐리게 두고 위 배너 + 가운데 카드
struct OfflineOverlay: View {
  let retryCount: Int
  let onRetry: () -> Void

  var body: some View {
    ZStack(alignment: .top) {
      Color.black.opacity(0.65).ignoresSafeArea()
      HStack(spacing: 8) {
        Image(systemName: "wifi.slash").font(.system(size: 15, weight: .semibold))
          .foregroundStyle(WePLiColor.inputError)
        Text("인터넷에 연결되어 있지 않아요").wepliFont(.subheadline, weight: .medium).foregroundStyle(WePLiColor.errorText)
        Spacer(minLength: 0)
      }
      .padding(.horizontal, 16)
      .frame(height: 44)
      .background(WePLiColor.destructive.opacity(0.16), in: RoundedRectangle(cornerRadius: 14))
      .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(WePLiColor.destructive.opacity(0.4), lineWidth: 0.5))
      .padding(.horizontal, 16)
      .padding(.top, 8)
      VStack(spacing: 10) {
        Text("연결을 확인해 주세요").wepliFont(.title3).foregroundStyle(WePLiColor.textPrimary)
        Text("Wi-Fi나 셀룰러 데이터를 켠 뒤 다시 시도해 주세요.\n보관함에 저장된 곡 목록은 계속 볼 수 있어요.")
          .wepliFont(.subheadline)
          .foregroundStyle(WePLiColor.textSecondary)
          .multilineTextAlignment(.center)
        // 원본의 흰 버튼은 DEC-009에 따라 보조 캡슐로
        Button(self.retryCount == 0 ? "다시 시도" : "다시 시도 (\(self.retryCount))", action: self.onRetry)
          .wepliFont(.callout, weight: .semibold)
          .foregroundStyle(WePLiColor.textPrimary)
          .padding(.horizontal, 28)
          .frame(height: 46)
          .background(WePLiColor.secondaryButtonFill, in: Capsule())
          .padding(.top, 8)
      }
      .padding(24)
      .frame(maxWidth: .infinity)
      .wepliGlass(in: RoundedRectangle(cornerRadius: 24))
      .padding(.horizontal, 20)
      .frame(maxHeight: .infinity)
    }
  }
}

struct RestrictionSheet: View {
  let restriction: CommunityRestriction
  let onAppeal: () -> Void
  let onPolicy: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      Circle().fill(WePLiColor.destructive.opacity(0.14)).frame(width: 64, height: 64)
        .overlay { Image(systemName: "nosign").font(.system(size: 26)).foregroundStyle(WePLiColor.inputError) }
        .accessibilityHidden(true)
      Text("커뮤니티 이용이\n잠시 제한되었어요").wepliFont(.title1, weight: .bold).foregroundStyle(WePLiColor.textPrimary)
      VStack(alignment: .leading, spacing: 12) {
        self.row("사유", self.restriction.reason)
        self.row("기간", "\(self.restriction.days)일 · \(SystemStatusText.date(self.restriction.until))까지")
        self.row("제한", self.restriction.scope)
      }
      .padding(16)
      .background(WePLiColor.surface1, in: RoundedRectangle(cornerRadius: 18))
      Text("제한 기간에도 음악 듣기, 투표, 보관함은 그대로 이용할 수 있어요.")
        .wepliFont(.subheadline)
        .foregroundStyle(WePLiColor.textSecondary)
      Spacer(minLength: 0)
      ExportSecondaryButton(title: "이의 신청하기", action: self.onAppeal)
      // 커뮤니티만 막으니 시트는 아래로 내려 닫을 수 있다
      Button("운영정책 보기", action: self.onPolicy)
        .wepliFont(.callout)
        .foregroundStyle(WePLiColor.accent)
        .frame(maxWidth: .infinity)
        .frame(height: 44)
    }
    .padding(.horizontal, 24)
    .padding(.top, 32)
    .padding(.bottom, 24)
  }

  private func row(_ label: String, _ value: String) -> some View {
    HStack(alignment: .top, spacing: 16) {
      Text(label).foregroundStyle(WePLiColor.textQuaternary).frame(width: 56, alignment: .leading)
      Text(value).foregroundStyle(WePLiColor.textPrimary)
    }
    .wepliFont(.subheadline)
  }
}

/// 이벤트 팝업 — 아래 떠 있는 카드. 「오늘 하루 보지 않기」 · 「닫기」
struct EventPopup: View {
  let event: SystemConfig.Event
  let onHideToday: () -> Void
  let onClose: () -> Void

  var body: some View {
    ZStack(alignment: .bottom) {
      Color.black.opacity(0.6).ignoresSafeArea()
      VStack(alignment: .leading, spacing: 0) {
        ZStack(alignment: .topLeading) {
          WePLiColor.sectionBand
          VStack(alignment: .leading, spacing: 6) {
            // 원본의 분홍 「EVENT」는 DEC-009에 따라 라벤더로
            Text("EVENT").wepliFont(.footnote, weight: .semibold).foregroundStyle(WePLiColor.accent)
            Text(self.event.title).wepliFont(.title2).foregroundStyle(WePLiColor.textPrimary)
          }
          .padding(.leading, 24)
          .padding(.top, 40)
        }
        .frame(height: 220)
        VStack(alignment: .leading, spacing: 12) {
          Text(self.event.body).wepliFont(.body).foregroundStyle(WePLiColor.textMuted)
          HStack {
            Button("오늘 하루 보지 않기", action: self.onHideToday).foregroundStyle(WePLiColor.textQuaternary)
            Spacer()
            Button("닫기", action: self.onClose).fontWeight(.semibold).foregroundStyle(WePLiColor.textPrimary)
          }
          .wepliFont(.subheadline)
          .frame(minHeight: 44)
          .padding(.horizontal, 6)
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
        .padding(.bottom, 22)
      }
      .background(WePLiColor.surface1)
      .clipShape(RoundedRectangle(cornerRadius: 40))
      .padding(8)
      // 미결정 — 원본 「자세히 보기」는 공지 · 이벤트(7a)로 가야 하지만 앱 맨 바깥이라 아직 잇지 않는다
    }
  }
}
