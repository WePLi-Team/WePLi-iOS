import ComposableArchitecture
import SwiftUI

// UI-7c 계정 관리 — 로그인 정보(Apple · Google · 가입일) · 차단한 사용자(차단 해제) · 회원 탈퇴

struct AccountManageContent: View {
  let store: StoreOf<AccountManagementFeature>

  var body: some View {
    WithPerceptionTracking {
      VStack(alignment: .leading, spacing: 26) {
        self.section("로그인 정보") {
          ForEach(LoginProvider.allCases, id: \.self) { provider in
            self.providerRow(provider)
          }
          HStack {
            Text("가입일").wepliFont(.body).foregroundStyle(WePLiColor.textPrimary)
            Spacer()
            Text(self.store.account?.joinedText ?? "").wepliFont(.body).foregroundStyle(WePLiColor.textQuaternary)
          }
          .padding(.horizontal, 16)
          .frame(height: 52)
          .accessibilityElement(children: .combine)
        }
        self.section("차단한 사용자") {
          if self.store.blocked.isEmpty {
            Text("차단한 사용자가 없어요")
              .wepliFont(.subheadline)
              .foregroundStyle(WePLiColor.textQuaternary)
              .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
              .padding(.horizontal, 16)
          }
          ForEach(self.store.blocked) { user in
            self.blockedRow(user)
          }
        }
        Button {
          self.store.send(.withdrawTapped)
        } label: {
          Text("회원 탈퇴")
            .wepliFont(.callout, weight: .medium)
            .foregroundStyle(WePLiColor.destructive)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(WePLiColor.surface1, in: RoundedRectangle(cornerRadius: 20))
            .contentShape(RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
      }
      .padding(.horizontal, 16)
    }
  }

  private func section(_ title: String, @ViewBuilder rows: () -> some View) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(title)
        .wepliFont(.footnote)
        .foregroundStyle(WePLiColor.textQuaternary)
        .padding(.horizontal, 16)
        .accessibilityAddTraits(.isHeader)
      VStack(spacing: 0, content: rows)
        .background(WePLiColor.surface1, in: RoundedRectangle(cornerRadius: 20))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
  }

  private func providerRow(_ provider: LoginProvider) -> some View {
    let email = self.store.account?.linked[provider]
    return HStack(spacing: 12) {
      AccountProviderIcon(provider: provider)
      VStack(alignment: .leading, spacing: 2) {
        Text(provider.name).wepliFont(.body).foregroundStyle(WePLiColor.textPrimary)
        if let email {
          Text(email).wepliFont(.caption).foregroundStyle(WePLiColor.textQuaternary).lineLimit(1)
        }
      }
      Spacer(minLength: 8)
      if email != nil {
        Text("연결됨").wepliFont(.footnote).foregroundStyle(WePLiColor.positive)
      } else {
        Button("연결하기") { self.store.send(.linkGoogleTapped) }
          .wepliFont(.footnote, weight: .semibold)
          .foregroundStyle(WePLiColor.accent)
          .frame(minHeight: 44)
          .buttonStyle(.plain)
      }
    }
    .padding(.horizontal, 16)
    .frame(height: 62)
    .overlay(alignment: .bottom) { AccountSeparator() }
  }

  private func blockedRow(_ user: BlockedUser) -> some View {
    HStack(spacing: 12) {
      Circle().fill(WePLiColor.surface2).frame(width: 36, height: 36).accessibilityHidden(true)
      Text(user.name).wepliFont(.body).foregroundStyle(WePLiColor.textPrimary)
        .frame(maxWidth: .infinity, alignment: .leading)
      Button {
        self.store.send(.unblockTapped(user.id))
      } label: {
        Text("차단 해제")
          .wepliFont(.footnote, weight: .semibold)
          .foregroundStyle(WePLiColor.textPrimary)
          .padding(.horizontal, 12)
          .frame(height: 30)
          .background(WePLiColor.disabledFill, in: Capsule())
          .frame(minHeight: 44)
          .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      .accessibilityLabel("\(user.name) 차단 해제")
    }
    .padding(.horizontal, 16)
    .frame(height: 60)
    .overlay(alignment: .bottom) { AccountSeparator() }
  }
}

/// 30pt 타일 — Apple(밝은 타일 + 검은 로고) · Google(어두운 타일 + G)
struct AccountProviderIcon: View {
  let provider: LoginProvider

  var body: some View {
    RoundedRectangle(cornerRadius: 8)
      .fill(self.provider == .apple ? WePLiColor.textPrimary : WePLiColor.surface3)
      .frame(width: 30, height: 30)
      .overlay {
        switch self.provider {
        case .apple:
          Image(systemName: "apple.logo").font(.system(size: 15, weight: .medium)).foregroundStyle(.black)
        case .google:
          // 미결정 — 4색 G 에셋이 없어 글자로 자리 표시
          Text("G").font(.system(size: 15, weight: .bold)).foregroundStyle(WePLiColor.textPrimary)
        }
      }
      .accessibilityHidden(true)
  }
}

struct AccountSeparator: View {
  var body: some View {
    Rectangle().fill(Color.white.opacity(0.08)).frame(height: 0.5)
  }
}
