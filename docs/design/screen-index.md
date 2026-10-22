# 화면 목록 (Screen Index)

원본: Claude Design 「위플리 iOS UI 개선」 — `docs/design/README.md`. 확인 2026-10-21(16 · 17차 추가. 이전: 2026-10-15 13 · 14차 추가, 8차는 v2 기준). 화면 ID는 원본 화면 번호이며, 이슈 · 커밋에서는 `UI-<번호>`로 쓴다(예: `UI-2c`).
플랫폼은 모두 iOS(iPhone). 상태 수 = 원본에 그려진 상태 · 변형 수(탭 바 glass/classic 변형 포함). 「별도 타깃」은 앱 외 Extension · capability가 필요한 화면.

| ID | 이름 | 상태 수 | 별도 타깃 | 원본 파일 |
|---|---|---|---|---|
| UI-1a | 로그인 | 1 |  | WePLi 1 Core.dc.html |
| UI-1b | 홈 | 4 |  | WePLi 1 Core.dc.html |
| UI-1c | 릴레이리스트 상세 | 4 |  | WePLi 1 Core.dc.html |
| UI-1d | 커뮤니티 | 5 |  | WePLi 1 Core.dc.html |
| UI-1e | 마이 | 2 |  | WePLi 1 Core.dc.html |
| UI-2a | 곡 검색 · 선택 | 7 |  | WePLi 2 Flows.dc.html |
| UI-2b | 게시글 작성 | 3 |  | WePLi 2 Flows.dc.html |
| UI-2c | 게시글 상세 · 댓글 | 4 |  | WePLi 2 Flows.dc.html |
| UI-2d | 곡 상세 — **v2(`2d2`, 2026-10-22)가 기준**: 아트 300 → 스크롤 104pt 동안 화면 폭 · 이 곡이 올라간 릴레이 · 들은 친구 · 댓글 | 2 |  | WePLi 2 Flows.dc.html |
| UI-2e | 명함 만들기 | 7 |  | WePLi 2 Flows.dc.html |
| UI-3a | 차트 (TOP 100) | 4 |  | WePLi 3 Figma Screens.dc.html |
| UI-3b | 노래 투표하기 | 3 |  | WePLi 3 Figma Screens.dc.html |
| UI-3c | 릴레이리스트 상태 | 3 |  | WePLi 3 Figma Screens.dc.html |
| UI-3d | 플레이리스트 상세 | 3 |  | WePLi 3 Figma Screens.dc.html |
| UI-3e | 내 정보 수정 | 3 |  | WePLi 3 Figma Screens.dc.html |
| UI-3f | 로그인 B안 · 앨범 캐러셀 | 1 |  | WePLi 3 Figma Screens.dc.html |
| UI-3g | 곡 공유 카드 | 1 |  | WePLi 3 Figma Screens.dc.html |
| UI-4a | 홈 v2 | 5 |  | WePLi 4 Improvements.dc.html |
| UI-4b | 지금 재생 중 | 3 |  | WePLi 4 Improvements.dc.html |
| UI-4c | 통합 검색 탭 | 3 |  | WePLi 4 Improvements.dc.html |
| UI-4d | 알림 | 4 |  | WePLi 4 Improvements.dc.html |
| UI-4e | 첫 로그인 온보딩 | 5 |  | WePLi 4 Improvements.dc.html |
| UI-5a | 사용자 프로필 · 신고/차단 | 10 |  | WePLi 5 New Screens.dc.html |
| UI-5b | 아티스트 | 2 |  | WePLi 5 New Screens.dc.html |
| UI-5c | 보관함 (내 활동) | 3 |  | WePLi 5 New Screens.dc.html |
| UI-5d | 알림 설정 | 5 |  | WePLi 5 New Screens.dc.html |
| UI-5e | 잠금화면 · Live Activity | 1 | Widget Extension | WePLi 5 New Screens.dc.html |
| UI-5f | 홈 화면 위젯 · Dynamic Island | 4 | Widget Extension | WePLi 5 New Screens.dc.html |
| UI-6a | 릴레이리스트 만들기 | 8 |  | WePLi 6 New Features.dc.html |
| UI-6b | 같이 듣기 · SharePlay | 4 | Group Activities capability | WePLi 6 New Features.dc.html |
| UI-6c | 오늘의 한 곡 | 2 |  | WePLi 6 New Features.dc.html |
| UI-6d | 취향 궁합 | 3 |  | WePLi 6 New Features.dc.html |
| UI-6e | 다른 앱에서 바로 추천 (공유 확장) | 4 | Share Extension | WePLi 6 New Features.dc.html |
| UI-6f | 위플리 결산 (스토리) | 5 |  | WePLi 6 New Features.dc.html |
| UI-7a | 공지사항 · 이벤트 | 7 |  | WePLi 7 Operations.dc.html |
| UI-7b | 고객센터 · 1:1 문의 | 7 |  | WePLi 7 Operations.dc.html |
| UI-7c | 계정 관리 · 회원 탈퇴 | 7 |  | WePLi 7 Operations.dc.html |
| UI-7d | 시스템 상태 화면(강제 업데이트·점검·오프라인·이용 제한·팝업) | 7 |  | WePLi 7 Operations.dc.html |
| UI-7e | 가려진 콘텐츠 · 이의 신청(신고 콘텐츠 처리) | 8 |  | WePLi 7 Operations.dc.html |
| UI-7f | 서비스 이용 가이드 | 4 |  | WePLi 7 Operations.dc.html |
| UI-7g | 앱 정보 · 약관 | 5 |  | WePLi 7 Operations.dc.html |
| UI-8a | 내 추천곡 크레딧 · 역전 알림 | 5 |  | WePLi 8 Fun Mechanics v2.dc.html (최신 · v1은 WePLi 8 Fun Mechanics.dc.html) |
| UI-8b | 곡 월드컵 투표 | 5 |  | WePLi 8 Fun Mechanics v2.dc.html (최신 · v1은 WePLi 8 Fun Mechanics.dc.html) |
| UI-8c | 바통 릴레이 | 4 |  | WePLi 8 Fun Mechanics v2.dc.html (최신 · v1은 WePLi 8 Fun Mechanics.dc.html) |
| UI-8d | 1위 예측 · 칭호와 배지 | 5 |  | WePLi 8 Fun Mechanics v2.dc.html (최신 · v1은 WePLi 8 Fun Mechanics.dc.html) |
| UI-8e | 완성 플리 크레딧 · Apple Music 내보내기 (→ UI-14b로 대체) | 4 |  | WePLi 8 Fun Mechanics v2.dc.html (최신 · v1은 WePLi 8 Fun Mechanics.dc.html) |
| UI-8f | 시즌 랭킹 · 인기 호스트 | 3 |  | WePLi 8 Fun Mechanics v2.dc.html (최신 · v1은 WePLi 8 Fun Mechanics.dc.html) |
| UI-9a | 홈 B안 · 리스트형 릴레이 | 2 |  | WePLi 9 Figma Variants.dc.html |
| UI-9b | 홈 C안 · Relay♪ist | 2 |  | WePLi 9 Figma Variants.dc.html |
| UI-9c | 게시글 상세 · 플레이리스트 타입 | 1 |  | WePLi 9 Figma Variants.dc.html |
| UI-9d | 게시글 상세 · 일반 타입 (노래로 답하기) | 3 |  | WePLi 9 Figma Variants.dc.html |
| UI-9e | 곡 추가 시트 · 플리 가져오기 | 5 |  | WePLi 9 Figma Variants.dc.html |
| UI-10a | 릴레이 탭 | 5 |  | WePLi 10 Essentials.dc.html |
| UI-10b | 다른 사람 명함 보기 | 2 |  | WePLi 10 Essentials.dc.html |
| UI-10c | 팔로워 · 팔로잉 | 4 |  | WePLi 10 Essentials.dc.html |
| UI-10d | 내 플레이리스트 · 편집 | 2 |  | WePLi 10 Essentials.dc.html |
| UI-10e | 내 게시글 수정·삭제 · 답글 | 7 |  | WePLi 10 Essentials.dc.html |
| UI-10f | 로딩 · 빈 상태 | 5 |  | WePLi 10 Essentials.dc.html |
| UI-11a | 내 음악 앱으로 내보내기 (Apple Music · Spotify · YouTube Music) (→ UI-14a–14o로 대체) | 8 |  | WePLi 11 Export.dc.html |
| UI-11b | 연결된 음악 서비스 | 3 |  | WePLi 11 Export.dc.html |
| UI-11c | 바통 초대 받기 (초대 링크로 들어왔을 때) | 3 |  | WePLi 11 Export.dc.html |
| UI-11d | 이의 신청 | 3 |  | WePLi 11 Export.dc.html |
| UI-11e | 내 명함 · 수정 · 테마 | 3 |  | WePLi 11 Export.dc.html |
| UI-12a | 통합 홈 · iOS 26 | 4 | | WePLi 12 iOS 16.dc.html + HomeFeed.dc.html |
| UI-12b | 통합 홈 · iOS 16 (iPhone 14 Pro) | 3 | | WePLi 12 iOS 16.dc.html + HomeFeed.dc.html |
| UI-12c | 통합 홈 · iPhone SE · 8 (iOS 16, 375×667) | 2 | | WePLi 12 iOS 16.dc.html + HomeFeed.dc.html |
| UI-12d | iOS 26 → iOS 16 크롬 비교 (공통 규칙) | 0 | | WePLi 12 iOS 16.dc.html |
| UI-13a | 연결과 공개 범위 | 3 | MusicKit · Spotify · Last.fm | WePLi 13 Now Playing v2.dc.html (v1은 WePLi 13 Now Playing.dc.html) |
| UI-13b | 친구 피드 — 커뮤니티 › 친구 | 2 |  | WePLi 13 Now Playing v2.dc.html (v1은 WePLi 13 Now Playing.dc.html) |
| UI-13c | 친구 프로필 (A안) | 4 |  | WePLi 13 Now Playing v2.dc.html (v1은 WePLi 13 Now Playing.dc.html) |
| UI-13d | 그룹 · 우리 넷 | 2 |  | WePLi 13 Now Playing v2.dc.html (v1은 WePLi 13 Now Playing.dc.html) |
| UI-13e | 잠금화면 위젯 | 2 | WidgetKit · App Group | WePLi 13 Now Playing v2.dc.html (v1은 WePLi 13 Now Playing.dc.html) |
| UI-13f | 지금 위플리 · 전체 트렌드 | 5 |  | WePLi 13 Now Playing v2.dc.html (v1은 WePLi 13 Now Playing.dc.html) |
| UI-13g | 친구 프로필 B안 · 커뮤니티까지 | 10 |  | WePLi 13 Now Playing v2.dc.html (v2에만 있음) |
| UI-14a | 완성 알림 | 1 | 푸시 | WePLi 14 Export Flow.dc.html |
| UI-14b | 완성 플리 · 기준 화면 | 6 |  | WePLi 14 Export Flow.dc.html |
| UI-14c | 서비스 선택 (어디로 담을까요) | 4 |  | WePLi 14 Export Flow.dc.html |
| UI-14d | 담기 설정 | 2 |  | WePLi 14 Export Flow.dc.html |
| UI-14e | Apple Music 접근 허용 | 2 | MusicKit | WePLi 14 Export Flow.dc.html |
| UI-14f | Apple Music 구독 필요 | 1 | MusicKit | WePLi 14 Export Flow.dc.html |
| UI-14g | Spotify 연결 | 2 | ASWebAuthenticationSession | WePLi 14 Export Flow.dc.html |
| UI-14h | 곡 맞추는 중 | 3 | 백그라운드 | WePLi 14 Export Flow.dc.html |
| UI-14i | 확인이 필요한 곡 | 3 |  | WePLi 14 Export Flow.dc.html |
| UI-14j | 다른 버전 고르기 | 5 |  | WePLi 14 Export Flow.dc.html |
| UI-14k | 담기 완료 | 2 |  | WePLi 14 Export Flow.dc.html |
| UI-14l | 지금 순위로 먼저 담기 (진행 중) | 2 |  | WePLi 14 Export Flow.dc.html |
| UI-14m | 내보낸 플리 · 변경 기록 | 2 |  | WePLi 14 Export Flow.dc.html |
| UI-14n | 문제가 생겼을 때 | 3 |  | WePLi 14 Export Flow.dc.html |
| UI-14o | 곡 목록으로 옮기기 | 4 |  | WePLi 14 Export Flow.dc.html |
| UI-16a | 로그인 시안 · 실시간 순위 | 1 |  | WePLi 16 Login.dc.html |
| UI-16b | 로그인 시안 · 한 곡씩 잇는 바통 | 1 |  | WePLi 16 Login.dc.html |
| UI-16c | 로그인 시안 · 어울려요 · 별로예요(투표 카드) | 1 |  | WePLi 16 Login.dc.html |
| UI-16d | 로그인 시안 · 흐르는 커버 벽 | 1 |  | WePLi 16 Login.dc.html |
| UI-16e | 로그인 시안 · 초대 링크로 왔을 때(먼저 둘러볼게요) | 1 |  | WePLi 16 Login.dc.html |
| UI-17a | 내 문의 내역 · 답변(목록 · 답변 · 이의 신청 결과 · 답변 대기) | 4 |  | WePLi 17 Ops Detail.dc.html |
| UI-17b | 커뮤니티 운영정책 · 이용 제한 단계 | 1 |  | WePLi 17 Ops Detail.dc.html |
| UI-17c | 내 가려진 글 | 1 |  | WePLi 17 Ops Detail.dc.html |
| UI-17d | 신고 · 기타 사유 · 이미 신고함 | 3 |  | WePLi 17 Ops Detail.dc.html |
| UI-17e | 탈퇴 유예 · 계정 되살리기 · 재가입 제한 | 3 |  | WePLi 17 Ops Detail.dc.html |
| UI-18a | 명함 만들기 안 · 단계형(취향 유형 → Best Pick → 한 줄 소개 → Instagram) | 5 |  | WePLi 18 Card Maker.dc.html |
| UI-18b | 명함 만들기 안 · 카드 위에서 바로 고치기(테마 4종) | 2 |  | WePLi 18 Card Maker.dc.html |
| UI-18c | 명함 만들기 안 · 듣기 기록으로 먼저 만들기(자동 초안) | 1 |  | WePLi 18 Card Maker.dc.html |
| UI-18d | 명함 만들기 안 · 세 곡 고르면 취향 유형(취향 테스트) | 2 |  | WePLi 18 Card Maker.dc.html |
| UI-18e | 명함이 없을 때 마이 시작점 · 받은 명함 줄 | 1 |  | WePLi 18 Card Maker.dc.html |
| UI-18f | Best Pick 고르기 시트(많이 들은 곡 · 좋아요한 곡) — 18a · 18b · 11e 공용 | 1 |  | WePLi 18 Card Maker.dc.html |
| UI-18g | 명함 완성 순간(뒤집기 · 디스크 회전) | 1 |  | WePLi 18 Card Maker.dc.html |
| UI-18h | 명함 공유(9:16 미리보기 · 배경 · 카카오톡) | 1 |  | WePLi 18 Card Maker.dc.html |
| UI-18i | 링크로 받은 명함(취향 궁합 · 팔로우 · 나도 만들기) | 1 |  | WePLi 18 Card Maker.dc.html |

합계 108개 = 99개 + 18a–18i 9개(2026-10-22 목차와 대조: 누락 0 · 중복 0, 2d v2는 같은 ID의 새 판). 이전 99개 = 89개 + 16a–16e 5개 + 17a–17e 5개(2026-10-21). 이전 합계 89개 = 67개(목차 66개 + 5f 「홈 화면 위젯」 분리) + 13a–13f 6개 + 13g 1개(v2에만 있고 목차 카드에는 없음) + 14a–14o 15개. 2026-10-15 목차와 대조: 누락 0 · 중복 0, 없어진 ID 0. `HomeFeed.dc.html`은 화면이 아니라 12a–12c가 불러 쓰는 홈 콘텐츠 컴포넌트(속성: os 26/16 · topY · heroH · padB).

## 대안 · 대체 관계

| 화면 | 관계 |
|---|---|
| UI-1b · UI-4a · UI-9a · UI-9b → UI-12a · 12b · 12c | 홈 시안 넷을 12차 통합 홈이 하나로 이음(DEC-006). 2026-10-15 갱신 17섹션: 히어로(4a) → TOP 100(1b) → 배너(1b) → 내 추천곡(8a) → 투표 중 릴레이(9a) → 1위 예측(8d) → 친구가 지금 듣는 중(13) → 지금 위플리에서 듣는 중(13) → 오늘의 플리(9a) → 시간대 추천 → 내 최애 가수(9b) → Fa♥orite · 내가 좋아요한 곡 → 커뮤니티 인기글(1d) → 인기 랭킹(1b) → 추천 플리(1b+9b) → 테마별 플리(1b) → Youtube Cover(9b+1b) |
| UI-12d | iOS 16 크롬 공통 규칙(탭 바 · 뒤로 · 시트 · 목록 · 검색) |
| UI-1a · UI-3f · UI-16a–16e | 로그인 A안(해시태그) · B안(앨범 캐러셀) · 16차 시안 5개 → **16d 흐르는 커버 벽 채택, 「먼저 둘러볼게요」 허용(DEC-032)** |
| UI-17d → UI-13g 신고 시트 | 「13g의 신고 시트를 보완했습니다」 — 신고는 17d가 기준 |
| UI-1c → UI-3b · UI-3c | 1c의 시트 투표는 3b 카드 투표 · 3c 상태 화면으로 대체(원본 명시) |
| UI-2c · UI-9c · UI-9d | 게시글 상세 한 곡 · 플레이리스트 · 일반 타입 |
| UI-2a · UI-9e · UI-4c | 곡 검색(전체 화면) · 곡 추가 시트(가벼운 추가) · 통합 검색 탭 — 서로 다른 화면 |
| UI-8e · UI-3c · UI-4a → UI-14b | 「완성 플리의 기준 화면입니다. 8e·3c·4a의 ‘완성된 플리’가 모두 여기로 옵니다.」(14 원문) — 8e는 만들지 않는다 |
| UI-11a → UI-14a–14o | 「11a 한 화면에 몰려 있던 흐름을 단계별 화면 15개로 나눴습니다」(14 원문). 11b–11e는 그대로 |
| UI-13c · UI-13g → UI-5a | 친구 프로필 A안 · B안 → **13g B안 채택, 5a를 대신함(DEC-010)** |
| UI-13 · UI-4b | 13은 소셜 「지금 듣는 음악」 상태, 4b는 앱 안 전체 화면 플레이어 — 서로 다른 화면(대체 관계 없음) |
| UI-10a | 1–4차의 「차트」 탭을 「릴레이」 탭으로 대체 |
| UI-2d → UI-2d v2 | 같은 파일에 옛 2d와 「2d v2 곡 상세 · 개선」이 함께 있다. 사용자가 v2로 개선했다고 알림(2026-10-22) → v2 기준. 파일 안 흐름 목록은 아직 옛 `#2d`로 링크 |
| UI-2e · UI-11e → UI-18a–18i | 18차는 「명함 만들기, 네 가지 방법과 그 앞뒤」. 2e를 이전 입력 화면이라 부르고 18b는 11e와 합칠 수 있다고 함. **어느 안을 채택할지 원본에 없음** → 결정 필요 |
