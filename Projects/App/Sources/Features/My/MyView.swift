import ComposableArchitecture
import SwiftUI

// REQ-070 · UI-1e — 마이 탭

struct MyView: View {
  let store: StoreOf<MyFeature>

  var body: some View {
    WithPerceptionTracking {
      ScrollView {
        VStack(alignment: .leading, spacing: 0) {
          self.header
          if let profile = self.store.profile {
            MyProfileCard(profile: profile) { self.store.send(.profileTapped) }
          } else if !self.store.loadFailed {
            WePLiSkeletonBlock(height: 150, cornerRadius: 24, color: WePLiColor.surface1)
              .padding(.horizontal, 16)
              .wepliPulse()
          }
          self.groups
            .padding(.top, 28)
          self.logoutButton
            .padding(.top, 12)
        }
        .padding(.bottom, 24)
      }
      .background(WePLiColor.background)
      .toolbar(.hidden, for: .navigationBar)
      .onAppear { self.store.send(.onAppear) }
    }
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack {
        Spacer()
        Button {
          self.store.send(.businessCardButtonTapped)
        } label: {
          Label("내 명함", systemImage: "person.text.rectangle")
            .wepliFont(.body, weight: .semibold)
            .foregroundStyle(WePLiColor.textPrimary)
            .padding(.leading, 12)
            .padding(.trailing, 16)
            .frame(height: 44)
            .wepliGlass(in: Capsule())
        }
        .buttonStyle(.plain)
      }
      .frame(height: 48)
      .padding(.horizontal, 16)

      Text("마이")
        .wepliFont(.screenTitle)
        .foregroundStyle(WePLiColor.textPrimary)
        .padding(.horizontal, 20)
        .padding(.top, 2)
        .padding(.bottom, 18)
        .accessibilityAddTraits(.isHeader)
    }
  }

  private var groups: some View {
    VStack(spacing: 28) {
      ForEach(self.store.sections, id: \.self) { section in
        let menus = section.menus(isDeveloperModeEnabled: self.store.isDeveloperModeEnabled)
        WePLiListGroup(title: section.title) {
          ForEach(Array(menus.enumerated()), id: \.element) { index, menu in
            WePLiListRow(
              systemImage: menu.systemImage,
              title: menu.title,
              showsSeparator: index < menus.count - 1 || section == .appInfo,
              action: { self.store.send(.menuTapped(menu)) }
            )
          }
          if section == .appInfo {
            WePLiListRow(
              systemImage: "info.circle",
              title: "앱 버전",
              value: self.store.appVersion,
              showsSeparator: false
            )
          }
        }
      }
    }
  }

  private var logoutButton: some View {
    Button {
      self.store.send(.logoutTapped)
    } label: {
      Text("로그아웃")
        .wepliFont(.callout, weight: .medium)
        .foregroundStyle(WePLiColor.destructive)
        .frame(maxWidth: .infinity)
        .frame(height: 52)
        .background(WePLiColor.surface1, in: RoundedRectangle(cornerRadius: 20))
    }
    .buttonStyle(.plain)
    .padding(.horizontal, 16)
  }
}

#Preview {
  NavigationStack {
    MyView(store: Store(initialState: MyFeature.State()) { MyFeature() })
  }
}
