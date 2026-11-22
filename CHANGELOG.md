# Changelog

## [0.5.0](https://github.com/michael11albrecht/mitlio/compare/mitlio-v0.4.0...mitlio-v0.5.0) (2026-11-22)


### Features

* **app:** profile photo from camera or gallery, local only (PU-T13) ([#292](https://github.com/michael11albrecht/mitlio/issues/292)) ([9df16c7](https://github.com/michael11albrecht/mitlio/commit/9df16c78d8a0e6da7fd971c7f161d8769fed0381))
* **app:** recurring expenses: rules, catch-up on start, form chip, list, DebugDrive (P9-T03) ([#295](https://github.com/michael11albrecht/mitlio/issues/295)) ([fa7c239](https://github.com/michael11albrecht/mitlio/commit/fa7c2394ec0ae7c1abf1da91082ef83644ce1b09))
* **domain:** parseReceipt turns OCR lines into a ReceiptDraft (P9r-T03) ([#291](https://github.com/michael11albrecht/mitlio/issues/291)) ([15b8bf7](https://github.com/michael11albrecht/mitlio/commit/15b8bf76559e267e6b71d0fc3c3b02767be01edf))
* **supabase:** delete Auth audit rows with the account, daily audit purge ([#206](https://github.com/michael11albrecht/mitlio/issues/206)) ([#251](https://github.com/michael11albrecht/mitlio/issues/251)) ([1b8b042](https://github.com/michael11albrecht/mitlio/commit/1b8b042a6c468f278e8ac64a5ee83b3529bb35da))
* **supabase:** notify Edge Function, FCM client, outbox claim/retry, cron (P6b-T05, P6b-T10) ([#253](https://github.com/michael11albrecht/mitlio/issues/253)) ([19ec821](https://github.com/michael11albrecht/mitlio/commit/19ec821bfd3b981d3ec10df36e53af02c2caaac7))
* **supabase:** notify monitoring, Sentry cron check-ins and outbox health (P6b-T10) [stacked on [#253](https://github.com/michael11albrecht/mitlio/issues/253)] ([#268](https://github.com/michael11albrecht/mitlio/issues/268)) ([2d9163d](https://github.com/michael11albrecht/mitlio/commit/2d9163da1311aaaf3b127a6af79183b3ea5a874b))
* support mitlio tip jar behind remote flag, off by default (P7-T09) ([#282](https://github.com/michael11albrecht/mitlio/issues/282)) ([e1caca3](https://github.com/michael11albrecht/mitlio/commit/e1caca3f4223a589f79067ae60f765471c194814))


### Bug Fixes

* **supabase:** align generated DB types with generator output ([#296](https://github.com/michael11albrecht/mitlio/issues/296)) ([fda22c7](https://github.com/michael11albrecht/mitlio/commit/fda22c77eb219aef2e5a07522dd9c6e4b60d9f4a))

## [0.4.0](https://github.com/michael11albrecht/mitlio/compare/mitlio-v0.3.0...mitlio-v0.4.0) (2026-11-22)


### Features

* **app:** car setup flow and cost calculator (PU-T08, PU-T09) ([#254](https://github.com/michael11albrecht/mitlio/issues/254)) ([d34779d](https://github.com/michael11albrecht/mitlio/commit/d34779ddb82ed9c653e914b0f2485534830f3dfb))
* **app:** group integration and entry points for profile and cars (PU-T10, PU-T11) [stacked on [#239](https://github.com/michael11albrecht/mitlio/issues/239) [#245](https://github.com/michael11albrecht/mitlio/issues/245) [#254](https://github.com/michael11albrecht/mitlio/issues/254) [#249](https://github.com/michael11albrecht/mitlio/issues/249)] ([#267](https://github.com/michael11albrecht/mitlio/issues/267)) ([1deba61](https://github.com/michael11albrecht/mitlio/commit/1deba6196fe92740417a13242cbc6810563ca27a))
* **app:** guided setup step-flow framework (PU-T05) ([#245](https://github.com/michael11albrecht/mitlio/issues/245)) ([5aee629](https://github.com/michael11albrecht/mitlio/commit/5aee62999d8cea981b4e7c054c0c2d0a2e898152))
* **app:** illustration set as CustomPainter widgets (PU-T06) ([#247](https://github.com/michael11albrecht/mitlio/issues/247)) ([47cd58b](https://github.com/michael11albrecht/mitlio/commit/47cd58bddb87325c0cb70ee6f06a6a4600424864))
* **app:** point prod build at the mitlio-prod Supabase project ([#271](https://github.com/michael11albrecht/mitlio/issues/271)) ([d7f0ab3](https://github.com/michael11albrecht/mitlio/commit/d7f0ab30129068e8ea925f1b37b86095447d0c03))
* **app:** profile flow (PU-T07) [stacked on [#239](https://github.com/michael11albrecht/mitlio/issues/239) and [#245](https://github.com/michael11albrecht/mitlio/issues/245)] ([#249](https://github.com/michael11albrecht/mitlio/issues/249)) ([044638a](https://github.com/michael11albrecht/mitlio/commit/044638a177fe859951a16427ba702fc2c0a6db1f))
* **app:** push notifications app side without Firebase (P6b-T06..T09) ([#252](https://github.com/michael11albrecht/mitlio/issues/252)) ([d5b4bd0](https://github.com/michael11albrecht/mitlio/commit/d5b4bd0d66214cd2325f25e1a6da81df1740994f))
* **app:** rare flows on the step flow: first group, commute route, month settlement (PU-T12) [stacked on [#267](https://github.com/michael11albrecht/mitlio/issues/267)] ([#270](https://github.com/michael11albrecht/mitlio/issues/270)) ([78ff36d](https://github.com/michael11albrecht/mitlio/commit/78ff36ddf74f8a19850eb865473989e4c8ad5781))
* **app:** read Sentry DSN from AppConfig, full scrubber fixture test (P7-T08) ([#241](https://github.com/michael11albrecht/mitlio/issues/241)) ([57a6079](https://github.com/michael11albrecht/mitlio/commit/57a6079c1857e3f49d53e44f60dfeab882128edd))
* **app:** Settings &gt; Feedback form, ViewModel, repository, DebugDrive handlers (P7-T10, ADR-29) ([#283](https://github.com/michael11albrecht/mitlio/issues/283)) ([f470d7b](https://github.com/michael11albrecht/mitlio/commit/f470d7b153f2ec4f5e0c985c7124028f7057686c))
* **app:** share my QR code via share sheet (PU-T16) [stacked on [#267](https://github.com/michael11albrecht/mitlio/issues/267)] ([#269](https://github.com/michael11albrecht/mitlio/issues/269)) ([2782f12](https://github.com/michael11albrecht/mitlio/commit/2782f12030b8f47be2dea0650284617ba371fa7a))
* **db:** profile, personal vehicles and vehicle source link, schema v7 (PU-T04) ([#239](https://github.com/michael11albrecht/mitlio/issues/239)) ([7203b90](https://github.com/michael11albrecht/mitlio/commit/7203b90728d3710fa171c052bbd8417c093e7080))
* **domain:** PayPal.Me handle, vehicle extra cost per km, operating-cost check (PU-T02, PU-T03, PU-T15) ([#235](https://github.com/michael11albrecht/mitlio/issues/235)) ([a237c52](https://github.com/michael11albrecht/mitlio/commit/a237c52930c6538fdb4f94451d953b5cf5e32f9b))
* **domain:** recurrence rule engine for recurring expenses (P9-T03) ([#266](https://github.com/michael11albrecht/mitlio/issues/266)) ([d361018](https://github.com/michael11albrecht/mitlio/commit/d361018f60d22d64cd47fabb60603a93631f2eba))
* **supabase:** push notification tables, outbox triggers, notify logic (P6b-T02, P6b-T03, P6b-T04) ([#246](https://github.com/michael11albrecht/mitlio/issues/246)) ([d65772f](https://github.com/michael11albrecht/mitlio/commit/d65772f2f8f0519ad37f5c3eed8dcc69b8d911a5))
* **supabase:** submit-feedback Edge Function, private bucket, retention job (P7-T10) ([#281](https://github.com/michael11albrecht/mitlio/issues/281)) ([f2dac17](https://github.com/michael11albrecht/mitlio/commit/f2dac1783c4ed3007dda827ac83c0e46256dec2c))
* **web,app:** Made with heart by Michael Albrecht credit ([#186](https://github.com/michael11albrecht/mitlio/issues/186), [#187](https://github.com/michael11albrecht/mitlio/issues/187)) ([#225](https://github.com/michael11albrecht/mitlio/issues/225)) ([a888562](https://github.com/michael11albrecht/mitlio/commit/a888562d6e8fa1cd0e47d6189f8c943a73cde157))
* **web:** from-to route field on the calculator, behind ROUTE_WEB (PW-T12, [#207](https://github.com/michael11albrecht/mitlio/issues/207)) ([#280](https://github.com/michael11albrecht/mitlio/issues/280)) ([f0055fb](https://github.com/michael11albrecht/mitlio/commit/f0055fbe8e397a92c3d1124a3a72630772c2b448))
* **web:** render sync privacy text, drop push text until P6b ([#263](https://github.com/michael11albrecht/mitlio/issues/263)) ([#264](https://github.com/michael11albrecht/mitlio/issues/264)) ([b1e4b66](https://github.com/michael11albrecht/mitlio/commit/b1e4b667ffd991bb96086c98f827aab8f1d94b1f))


### Bug Fixes

* **app:** credit line gap and check mark over avatar chips ([#236](https://github.com/michael11albrecht/mitlio/issues/236), [#237](https://github.com/michael11albrecht/mitlio/issues/237)) ([#250](https://github.com/michael11albrecht/mitlio/issues/250)) ([1f275e5](https://github.com/michael11albrecht/mitlio/commit/1f275e5bfd21f2992b8decaec9e7bbd09d44921e))
* **balances:** removed members no longer break balances; settle sheet shows what others owe ([#136](https://github.com/michael11albrecht/mitlio/issues/136), [#141](https://github.com/michael11albrecht/mitlio/issues/141)) ([#222](https://github.com/michael11albrecht/mitlio/issues/222)) ([a800efb](https://github.com/michael11albrecht/mitlio/commit/a800efbd4d356db07cc4fcde1f327872df55af41))
* **groups:** focus the member rename field and reject duplicate names ([#138](https://github.com/michael11albrecht/mitlio/issues/138), [#144](https://github.com/michael11albrecht/mitlio/issues/144)) ([#224](https://github.com/michael11albrecht/mitlio/issues/224)) ([b941051](https://github.com/michael11albrecht/mitlio/commit/b941051b2c7aa1e094da9739d0cbb3254c0938f0))
* **trip:** share text names payee and total; plausibility limits; UTC seed dates and app category keys ([#223](https://github.com/michael11albrecht/mitlio/issues/223)) ([6a0465b](https://github.com/michael11albrecht/mitlio/commit/6a0465b8afae2cd5a5f95a067367c7eda43f5cf0))
* **web:** fuel source/note to footer, nearby only when supported, center chips ([#211](https://github.com/michael11albrecht/mitlio/issues/211)) ([f93013f](https://github.com/michael11albrecht/mitlio/commit/f93013f65f98f029f7ebe46e37e3c27a53c069f6))

## [0.3.0](https://github.com/michael11albrecht/mitlio/compare/mitlio-v0.2.0...mitlio-v0.3.0) (2026-11-19)


### Features

* **config:** dev flavor uses staging Supabase; fix secrets gate ([#153](https://github.com/michael11albrecht/mitlio/issues/153)) ([a91f0f5](https://github.com/michael11albrecht/mitlio/commit/a91f0f527468c89a5327fa9fd206f0ea947c78ca))
* **db:** app_config min_supported_version and join retry hint (P6-T16a) ([#179](https://github.com/michael11albrecht/mitlio/issues/179)) ([2e2d92a](https://github.com/michael11albrecht/mitlio/commit/2e2d92a527cf2097cf1fa1770ba6784a45aac097))
* **db:** Drift v5 local sync state, pull cursors, persisted HLC node id (P6-T09a) ([#175](https://github.com/michael11albrecht/mitlio/issues/175)) ([4b0368d](https://github.com/michael11albrecht/mitlio/commit/4b0368d1514f3f22183598b1286d38db47f97e77))
* **domain:** aggregate merge decision, LWW on HLC with tombstones (P6-T11a) ([#172](https://github.com/michael11albrecht/mitlio/issues/172)) ([fb7648c](https://github.com/michael11albrecht/mitlio/commit/fb7648cca3c34ef23cd14c7d082861a3d2368c41))
* **legal:** draft Impressum and Datenschutzerklärung (DE/EN) [Entwurf] ([#124](https://github.com/michael11albrecht/mitlio/issues/124)) ([e718881](https://github.com/michael11albrecht/mitlio/commit/e7188817045eda9262a6a829e4e023dfdd91ad8f))
* **legal:** retention as code, contact form + retention text, address from env (P7-T07) ([#182](https://github.com/michael11albrecht/mitlio/issues/182)) ([3399903](https://github.com/michael11albrecht/mitlio/commit/3399903c9c7768849f5e59f18358656d6468397a))
* **privacy:** sync privacy sections, inactive-account cleanup, release gate ([#188](https://github.com/michael11albrecht/mitlio/issues/188)) ([#195](https://github.com/michael11albrecht/mitlio/issues/195)) ([cc34a53](https://github.com/michael11albrecht/mitlio/commit/cc34a538da5c68d608ce82cb704050304b9ba080))
* **remote:** supabase client wiring and RemoteError mapping (P6-T07a) ([#173](https://github.com/michael11albrecht/mitlio/issues/173)) ([17ca354](https://github.com/michael11albrecht/mitlio/commit/17ca35442a6c30c77a1233e948125decb672bc40))
* **rides:** car model suggestions prefill consumption (P9-T09) ([#176](https://github.com/michael11albrecht/mitlio/issues/176)) ([d59b78a](https://github.com/michael11albrecht/mitlio/commit/d59b78a30d5d78e53bf3015a052e5659289e03b6))
* **rides:** ride distance from start and destination (P9-T08) ([#174](https://github.com/michael11albrecht/mitlio/issues/174)) ([e80594d](https://github.com/michael11albrecht/mitlio/commit/e80594d52ebed375f8e9dda16c51404b56581bf6)), closes [#130](https://github.com/michael11albrecht/mitlio/issues/130)
* **sync:** anonymous sign-in, session persistence, hide unconfigured providers (P6-T07) ([#180](https://github.com/michael11albrecht/mitlio/issues/180)) ([15023b2](https://github.com/michael11albrecht/mitlio/commit/15023b2c12ebbd463f7646fb1bcce18378c896a0))
* **sync:** app version gate, blocks sync only, store link (P6-T16) ([#201](https://github.com/michael11albrecht/mitlio/issues/201)) ([550abfa](https://github.com/michael11albrecht/mitlio/commit/550abfa5ed64759a712a78fa4e8c2843e1373271))
* **sync:** join deep links, app links + AASA + web fallback (P6-T14c) ([#208](https://github.com/michael11albrecht/mitlio/issues/208)) ([00c1e16](https://github.com/michael11albrecht/mitlio/commit/00c1e1621b49204e6ec1365ad6df12a326954edb)), closes [#166](https://github.com/michael11albrecht/mitlio/issues/166)
* **sync:** join flow and Wer bist du? picker (P6-T14b) ([#203](https://github.com/michael11albrecht/mitlio/issues/203)) ([4284909](https://github.com/michael11albrecht/mitlio/commit/42849091c4b5ceb706f9bde2ace142798fd44b25))
* **sync:** outbox enqueue for shared groups in the write transaction (P6-T09) ([#184](https://github.com/michael11albrecht/mitlio/issues/184)) ([289c902](https://github.com/michael11albrecht/mitlio/commit/289c9029dc7f5de1a85255269fcb043a0837c597))
* **sync:** share a local group, upload full history (P6-T15) ([#198](https://github.com/michael11albrecht/mitlio/issues/198)) ([3e3f813](https://github.com/michael11albrecht/mitlio/commit/3e3f8130e67200f17cfb8a0f303f583e9fabd0ec))
* **sync:** share sheet with link and QR, owner can make a new link (P6-T14a) ([#200](https://github.com/michael11albrecht/mitlio/issues/200)) ([24d0280](https://github.com/michael11albrecht/mitlio/commit/24d0280562f1896892f59b7acadbba913637187f))
* **sync:** sync triggers + status line, no realtime (P6-T12) ([#199](https://github.com/michael11albrecht/mitlio/issues/199)) ([d5633f6](https://github.com/michael11albrecht/mitlio/commit/d5633f66bcdde4396cd3a90bcc7a9a291f07d7ba))
* **sync:** SyncRemote, fake server and SyncService.push (P6-T10) ([#196](https://github.com/michael11albrecht/mitlio/issues/196)) ([22fae38](https://github.com/michael11albrecht/mitlio/commit/22fae384e5867ac62fcf41344832f5b6662ac19a))
* **sync:** SyncService.pull with cursor, LWW apply and no echo (P6-T11) ([#197](https://github.com/michael11albrecht/mitlio/issues/197)) ([070a916](https://github.com/michael11albrecht/mitlio/commit/070a916473e6f75299a6be000d48d2674c34bab8))
* **sync:** verbunden badge, owner disconnects a phone with undo, Das bin ich (P6-T14d) ([#205](https://github.com/michael11albrecht/mitlio/issues/205)) ([b7ebe7b](https://github.com/michael11albrecht/mitlio/commit/b7ebe7b2a3eba251a0d5961a9b6477ed73972c70))
* **web:** contact form via Resend EU (Impressum second contact channel) ([#183](https://github.com/michael11albrecht/mitlio/issues/183)) ([3a8247b](https://github.com/michael11albrecht/mitlio/commit/3a8247b2331e04ac6abaa74704ccb4d54cae5eb6))


### Bug Fixes

* **auth:** keychain delete failure propagates on data deletion ([#192](https://github.com/michael11albrecht/mitlio/issues/192)) ([b2f273d](https://github.com/michael11albrecht/mitlio/commit/b2f273dcd8b173f679ac943e82820e6a79e31183))
* **web:** keep space before privacy link on contact page ([#189](https://github.com/michael11albrecht/mitlio/issues/189)) ([#194](https://github.com/michael11albrecht/mitlio/issues/194)) ([841af98](https://github.com/michael11albrecht/mitlio/commit/841af9863ecc02362ccedb97950fcc5b837cc9ad))
* **web:** visible fuel failure, breakdown chevron, fuel CORS in deploy ([#209](https://github.com/michael11albrecht/mitlio/issues/209)) ([37395c6](https://github.com/michael11albrecht/mitlio/commit/37395c6e2edd4ab642040bf510a940d3c8cae8c2))

## [0.2.0](https://github.com/michael11albrecht/mitlio/compare/mitlio-v0.1.0...mitlio-v0.2.0) (2026-11-15)


### Features

* **balances:** count open rides live in balances and settle ([#132](https://github.com/michael11albrecht/mitlio/issues/132)) ([f28894f](https://github.com/michael11albrecht/mitlio/commit/f28894f8f8948ae52c48de89f921a2e8d0050930))
* **db:** fuel price cache and fuel-prices Edge Function (P6c-T02..T04, T06) ([#102](https://github.com/michael11albrecht/mitlio/issues/102)) ([72870af](https://github.com/michael11albrecht/mitlio/commit/72870af30d61413d836eb755d0348ea33de1a994))
* **db:** people vs accounts, owner role, rotating invite link (ADR-24) ([#121](https://github.com/michael11albrecht/mitlio/issues/121)) ([d847efe](https://github.com/michael11albrecht/mitlio/commit/d847efe4c5179547b191e69688eb3a8cb53ea292))
* **db:** rate limit and audit join_group ([#89](https://github.com/michael11albrecht/mitlio/issues/89)) ([#117](https://github.com/michael11albrecht/mitlio/issues/117)) ([0bafe7d](https://github.com/michael11albrecht/mitlio/commit/0bafe7d77448a62195cfd3d2e4a397b44c8621e1))
* **expenses:** edit history with revisions on client and server (P7-T03) ([#112](https://github.com/michael11albrecht/mitlio/issues/112)) ([60f12ff](https://github.com/michael11albrecht/mitlio/commit/60f12ff07fef93a327e417ccaa61cb078cd88560))
* **fuel:** fuel price service and chips in trip/ride forms (P6c-T05) ([#103](https://github.com/michael11albrecht/mitlio/issues/103)) ([ce02449](https://github.com/michael11albrecht/mitlio/commit/ce024496d520b1a1625fcc0322547372f35691c9))
* **fuel:** national average straight from the EU Oil Bulletin without a backend ([#133](https://github.com/michael11albrecht/mitlio/issues/133)) ([3632777](https://github.com/michael11albrecht/mitlio/commit/3632777c8e0ce638288d693a69f28335794a6727))
* **fuel:** opt-in nearby fuel prices with coarse location ([#115](https://github.com/michael11albrecht/mitlio/issues/115)) ([97be2a8](https://github.com/michael11albrecht/mitlio/commit/97be2a8c1c514d1af41a88e0a063f7f275c0395e))
* **fx:** ECB reference rates function and rate suggestion (P7-T02) ([#108](https://github.com/michael11albrecht/mitlio/issues/108)) ([8b815d6](https://github.com/michael11albrecht/mitlio/commit/8b815d6b612e987e242871e0b98cf05e8819ee57))
* **groups:** archived groups screen with restore ([#135](https://github.com/michael11albrecht/mitlio/issues/135)) ([4742557](https://github.com/michael11albrecht/mitlio/commit/47425573de2864bedf7e4a8b6006efff1c3552d6))
* **privacy:** delete my data on device and server (P7-T07) ([#116](https://github.com/michael11albrecht/mitlio/issues/116)) ([f574438](https://github.com/michael11albrecht/mitlio/commit/f574438958cd370e72c309f0e708956d6c92d017))
* **rides:** everyone drives by default, mark non-drivers, explain the rule ([#129](https://github.com/michael11albrecht/mitlio/issues/129)) ([fcd9245](https://github.com/michael11albrecht/mitlio/commit/fcd9245b23e5366aa110b13b53eed0efc8c814a7))
* **ui:** Fertig bar above the iOS number pad ([#134](https://github.com/michael11albrecht/mitlio/issues/134)) ([4c1f96e](https://github.com/michael11albrecht/mitlio/commit/4c1f96e0c986b35d66ce3a99e86f9cdb93ec2b00))
* **web:** clickable live fuel price chips (PW-T04) ([#106](https://github.com/michael11albrecht/mitlio/issues/106)) ([0d77a78](https://github.com/michael11albrecht/mitlio/commit/0d77a78d9154a9e214cf86fe6b394867ee3a49a8))
* **web:** English landing pages with hreflang pairs (PW-T07) ([#111](https://github.com/michael11albrecht/mitlio/issues/111)) ([b4559d9](https://github.com/michael11albrecht/mitlio/commit/b4559d915ab01badd048d8afe439bda0427ec380))
* **web:** firebase hosting with security headers and preview channels (PW-T10) ([#150](https://github.com/michael11albrecht/mitlio/issues/150)) ([8480a42](https://github.com/michael11albrecht/mitlio/commit/8480a42e58e354106baed8345b4772915f98ae3e))


### Bug Fixes

* no silent errors, specific fuel and failure messages ([#149](https://github.com/michael11albrecht/mitlio/issues/149)) ([b9c0668](https://github.com/michael11albrecht/mitlio/commit/b9c06683dd1683ef3ce8333a4c5e3e7a3c27f971))
* **rides:** log a ride for a past day inside the day sheet ([#126](https://github.com/michael11albrecht/mitlio/issues/126)) ([fdf28e7](https://github.com/michael11albrecht/mitlio/commit/fdf28e7c37294a71eb24fc09d7da7bd64be690cb))
* **ui:** dismiss the keyboard on tab, route change and drag ([#127](https://github.com/michael11albrecht/mitlio/issues/127)) ([18c100c](https://github.com/michael11albrecht/mitlio/commit/18c100c4c4938f184308c175501c2d3ed172619f))
* **ui:** undo snack bar auto-hides and can be closed ([#125](https://github.com/michael11albrecht/mitlio/issues/125)) ([b5c3997](https://github.com/michael11albrecht/mitlio/commit/b5c39970aefc45d5858f6e592dd7f4799d3e3787))
