import ComposableArchitecture
import SwiftUI

// REQ-082 · UI-5d — 알림 설정

struct NotificationSettingsView: View {
  let store: StoreOf<NotificationSettingsFeature>

  var body: some View {
    WithPerceptionTracking {
      ScrollView {
        if let settings = self.store.settings {
          VStack(alignment: .leading, spacing: 26) {
            VStack(alignment: .leading, spacing: 8) {
              SettingsCard {
                self.toggleRow("푸시 알림", detail: nil, isOn: settings.isPushEnabled, isLast: true, bold: true) {
                  self.store.send(.pushToggled($0))
                }
              }
              self.footnote("끄면 아래 알림을 모두 받지 않아요. iOS 설정 › WePLi › 알림에서도 바꿀 수 있어요.")
            }
            VStack(alignment: .leading, spacing: 26) {
              self.group("릴레이리스트", settings: settings, items: [.deadline, .rank, .completed])
              self.group("커뮤니티", settings: settings, items: [.comment, .like, .follower])
              self.quietHours(settings)
              self.promotion(settings)
            }
            // 전체를 끄면 아래 항목이 흐려지고 잠긴다(UI-5d 노트 02)
            .opacity(settings.isPushEnabled ? 1 : 0.35)
            .allowsHitTesting(settings.isPushEnabled)
            .disabled(!settings.isPushEnabled)
            .animation(.easeInOut(duration: 0.2), value: settings.isPushEnabled)
          }
          .padding(.horizontal, 16)
          .padding(.top, 18)
          .padding(.bottom, 32)
        } else if self.store.loadFailed {
          // 원본에 오류 화면이 없어 임시 문구 — 디자인 확인 필요
          Text("알림 설정을 불러오지 못했어요")
            .wepliFont(.callout, weight: .semibold)
            .foregroundStyle(WePLiColor.textPrimary)
            .frame(maxWidth: .infinity, minHeight: 300)
        } else {
          ProgressView().tint(WePLiColor.textTertiary).frame(maxWidth: .infinity, minHeight: 300)
        }
      }
      .safeAreaInset(edge: .top, spacing: 0) { self.navigationBar }
      .background(WePLiColor.background)
      .toolbar(.hidden, for: .navigationBar)
      .wepliToast(Binding(get: { self.store.toast }, set: {
        if $0 == nil {
          self.store.send(.toastDismissed)
        }
      }))
      .onAppear { self.store.send(.onAppear) }
    }
  }

  private var navigationBar: some View {
    ZStack {
      Text("알림 설정").wepliFont(.button).foregroundStyle(WePLiColor.textPrimary).accessibilityAddTraits(.isHeader)
      HStack {
        WePLiIconButton(systemName: "chevron.left", accessibilityLabel: "뒤로") { self.store.send(.backButtonTapped) }
        Spacer()
      }
    }
    .padding(.horizontal, 16)
    .frame(height: 48)
    .background(WePLiColor.background)
  }

  private func group(_ title: String, settings: NotificationSettings, items: [NotificationSetting]) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      self.header(title)
      SettingsCard {
        ForEach(Array(items.enumerated()), id: \.element) { index, item in
          self.toggleRow(
            item.title,
            detail: item.detail,
            isOn: settings.enabled.contains(item),
            isLast: index == items.count - 1
          ) {
            self.store.send(.settingToggled(item, $0))
          }
        }
      }
    }
  }

  private func quietHours(_ settings: NotificationSettings) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      self.header("방해 금지")
      SettingsCard {
        self.toggleRow(
          NotificationSetting.doNotDisturb.title,
          detail: nil,
          isOn: settings.enabled.contains(.doNotDisturb),
          isLast: false
        ) { self.store.send(.settingToggled(.doNotDisturb, $0)) }
        Button {
          self.store.send(.quietHoursTapped)
        } label: {
          HStack {
            Text("알림 받지 않는 시간").wepliFont(.callout).foregroundStyle(WePLiColor.textPrimary)
            Spacer()
            Text(settings.quietHours).wepliFont(.body).foregroundStyle(WePLiColor.textQuaternary).monospacedDigit()
            Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold))
              .foregroundStyle(WePLiColor.textDisabled)
          }
          .padding(.horizontal, 16)
          .frame(minHeight: 56)
          .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
      }
      self.footnote("이 시간에 온 알림은 아침에 한 번에 보여드려요")
    }
  }

  private func promotion(_ settings: NotificationSettings) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      self.header("기타")
      SettingsCard {
        self.toggleRow(
          NotificationSetting.promotion.title,
          detail: NotificationSetting.promotion.detail,
          isOn: settings.enabled.contains(.promotion),
          isLast: true
        ) { self.store.send(.settingToggled(.promotion, $0)) }
      }
      // 광고성 정보는 별도 동의와 동의 내역 안내가 필요하다(UI-5d 노트 03)
      if let date = settings.promotionConsentDate, settings.enabled.contains(.promotion) {
        self.footnote("광고성 정보 수신 동의 · \(date)")
      } else {
        self.footnote("광고성 정보 수신 거부 상태예요")
      }
    }
  }

  private func toggleRow(
    _ title: String,
    detail: String?,
    isOn: Bool,
    isLast: Bool,
    bold: Bool = false,
    onChange: @escaping (Bool) -> Void
  ) -> some View {
    Toggle(isOn: Binding(get: { isOn }, set: onChange)) {
      VStack(alignment: .leading, spacing: 2) {
        Text(title).wepliFont(.callout, weight: bold ? .semibold : .regular).foregroundStyle(WePLiColor.textPrimary)
        if let detail {
          Text(detail).wepliFont(.caption).foregroundStyle(WePLiColor.textQuaternary)
        }
      }
    }
    .tint(WePLiColor.accent)
    .padding(.horizontal, 16)
    .padding(.vertical, 10)
    .frame(minHeight: 56)
    .overlay(alignment: .bottom) {
      if !isLast {
        Rectangle().fill(Color.white.opacity(0.08)).frame(height: 0.5).padding(.leading, 16)
      }
    }
  }

  private func header(_ text: String) -> some View {
    Text(text).wepliFont(.footnote).foregroundStyle(WePLiColor.textQuaternary).padding(.horizontal, 4)
      .accessibilityAddTraits(.isHeader)
  }

  private func footnote(_ text: String) -> some View {
    Text(text).wepliFont(.caption).foregroundStyle(WePLiColor.textQuaternary).padding(.horizontal, 4)
  }
}

private struct SettingsCard<Content: View>: View {
  @ViewBuilder var content: () -> Content

  var body: some View {
    VStack(spacing: 0) { self.content() }
      .background(WePLiColor.surface1, in: RoundedRectangle(cornerRadius: 20))
  }
}

#Preview {
  NavigationStack {
    NotificationSettingsView(store: Store(initialState: NotificationSettingsFeature.State()) {
      NotificationSettingsFeature()
    })
  }
}
