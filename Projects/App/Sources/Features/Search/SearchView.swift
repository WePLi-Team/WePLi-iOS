import ComposableArchitecture
import SwiftUI

// REQ-080 · UI-4c · UI-12d
// iOS 26: 하단에 떠 있는 검색 캡슐 + 홈 원형 버튼(다른 탭은 접힘)
// iOS 16: 큰 제목 아래 검색창(시스템 searchable)

struct SearchView: View {
  @Perception.Bindable var store: StoreOf<SearchFeature>

  @Environment(\.wepliChrome)
  private var chrome

  static let prompt = "곡, 플레이리스트, 사람 검색"

  var body: some View {
    WithPerceptionTracking {
      Group {
        switch self.chrome {
        case .glass:
          self.content(showsTitle: true)
            .toolbar(.hidden, for: .navigationBar)
            .safeAreaInset(edge: .bottom, spacing: 0) { self.floatingSearchBar }
        case .material:
          self.content(showsTitle: false)
            .navigationTitle("검색")
            .navigationBarTitleDisplayMode(.large)
            .searchable(
              text: self.$store.query,
              placement: .navigationBarDrawer(displayMode: .always),
              prompt: Self.prompt
            )
        }
      }
      .background(WePLiColor.background)
      .onAppear { self.store.send(.onAppear) }
    }
  }

  private func content(showsTitle: Bool) -> some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 0) {
        if showsTitle {
          Text("검색")
            .wepliFont(.screenTitle)
            .foregroundStyle(WePLiColor.textPrimary)
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .accessibilityAddTraits(.isHeader)
        }
        if self.store.hasQuery {
          self.results
        } else {
          self.browse
        }
      }
      .padding(.bottom, 24)
    }
    .scrollDismissesKeyboard(.interactively)
  }

  // MARK: 검색어 없을 때

  private var browse: some View {
    VStack(alignment: .leading, spacing: 0) {
      if !self.store.recentQueries.isEmpty {
        Text("최근 검색어")
          .wepliFont(.callout, weight: .semibold)
          .foregroundStyle(WePLiColor.textPrimary)
          .padding(.horizontal, 20)
          .padding(.top, 22)
          .padding(.bottom, 10)
        ScrollView(.horizontal, showsIndicators: false) {
          HStack(spacing: 8) {
            ForEach(self.store.recentQueries, id: \.self) { query in
              SearchChip(title: query) { self.store.send(.suggestionTapped(query)) }
            }
          }
          .padding(.horizontal, 20)
        }
      }

      Text("둘러보기")
        .wepliFont(.headline)
        .foregroundStyle(WePLiColor.textPrimary)
        .padding(.horizontal, 20)
        .padding(.top, 30)
        .padding(.bottom, 12)
      LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
        ForEach(SearchBrowseTag.all, id: \.self) { tag in
          SearchTagTile(tag: tag) { self.store.send(.suggestionTapped(tag)) }
        }
      }
      .padding(.horizontal, 20)
    }
  }

  // MARK: 검색 결과

  private var results: some View {
    VStack(alignment: .leading, spacing: 0) {
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 8) {
          ForEach(SearchScope.allCases, id: \.self) { scope in
            SearchChip(title: scope.title, isSelected: self.store.searchScope == scope) {
              self.store.send(.scopeSelected(scope))
            }
          }
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
        .padding(.bottom, 6)
      }

      let results = self.store.results
      if !results.songs.isEmpty {
        SearchSectionHeader(title: "곡")
        ForEach(results.songs) { song in
          SearchResultRow(kind: .song, title: song.title, subtitle: "곡 · \(song.artist)") {
            self.store.send(.songTapped(song.id))
          }
        }
      }
      if !results.lists.isEmpty {
        SearchSectionHeader(title: "플레이리스트 · 릴레이")
        ForEach(results.lists) { list in
          SearchResultRow(kind: .list, title: list.title, subtitle: list.subtitle) {
            self.store.send(.listTapped(list.id))
          }
        }
      }
      if !results.users.isEmpty {
        SearchSectionHeader(title: "사용자")
        ForEach(results.users) { user in
          SearchUserRow(user: user) { self.store.send(.userTapped(user.id)) }
        }
      }
      if self.store.showsNoResults {
        VStack(spacing: 8) {
          Text("검색 결과가 없어요")
            .wepliFont(.callout, weight: .semibold)
            .foregroundStyle(WePLiColor.textPrimary)
          Text("다른 검색어나 둘러보기 태그를 눌러보세요")
            .wepliFont(.subheadline)
            .foregroundStyle(WePLiColor.textQuaternary)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
        .padding(.horizontal, 20)
      }
    }
  }

  // MARK: iOS 26 하단 검색 바 (좌우 20 · 아래 30 · 높이 54)

  private var floatingSearchBar: some View {
    HStack(spacing: 10) {
      Button {
        self.store.send(.homeButtonTapped)
      } label: {
        Image(systemName: "house")
          .font(.system(size: 20, weight: .medium))
          .foregroundStyle(WePLiColor.tabInactiveGlass)
          .frame(width: 54, height: 54)
          .wepliGlass(in: Circle())
      }
      .buttonStyle(.plain)
      .accessibilityLabel("홈")

      HStack(spacing: 8) {
        Image(systemName: "magnifyingglass")
          .font(.system(size: 17, weight: .semibold))
          .foregroundStyle(WePLiColor.accent)
        TextField(Self.prompt, text: self.$store.query)
          .wepliFont(.callout)
          .foregroundStyle(WePLiColor.textPrimary)
          .submitLabel(.search)
          .frame(height: 50)
        if !self.store.query.isEmpty {
          Button {
            self.store.send(.clearButtonTapped)
          } label: {
            Image(systemName: "xmark.circle.fill")
              .font(.system(size: 20))
              .foregroundStyle(WePLiColor.textDisabled)
              .frame(width: 34, height: 34)
          }
          .buttonStyle(.plain)
          .accessibilityLabel("검색어 지우기")
        }
      }
      .padding(.leading, 16)
      .padding(.trailing, 8)
      .frame(height: 54)
      .wepliGlass(in: Capsule())
    }
    .padding(.horizontal, 20)
    .padding(.bottom, 30)
    .ignoresSafeArea(edges: .bottom)
    .background(alignment: .bottom) {
      WePLiGradient.bottomFade
        .frame(height: 130)
        .ignoresSafeArea(edges: .bottom)
        .allowsHitTesting(false)
    }
  }
}

#Preview("iOS 26") {
  NavigationStack {
    SearchView(store: Store(initialState: SearchFeature.State()) { SearchFeature() })
  }
}

#Preview("iOS 16") {
  NavigationStack {
    SearchView(store: Store(initialState: SearchFeature.State()) { SearchFeature() })
  }
  .environment(\.wepliChrome, .material)
}
