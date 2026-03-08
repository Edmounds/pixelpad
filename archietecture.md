# PixelPad Flutter 项目架构认知

> 文档范围：`/home/cqc/pixelpad/pixelpad`（Flutter 主应用）
>
> 仓库根目录 `/home/cqc/pixelpad` 下同时存在 `miniprogram/`，本文仅覆盖 Flutter 工程。

## 1. 项目定位与技术栈

- 项目名：`pixelpad`（见 `pixelpad/pubspec.yaml`）
- Dart/Flutter：`environment.sdk: ^3.10.8`
- 核心依赖：`http`、`shared_preferences`、`image_picker`、`image_editor`、`flutter_svg`
- 代码规范：`analysis_options.yaml` 引入 `package:flutter_lints/flutter.yaml`

## 2. 目录与分层（当前实现）

Flutter 工程根目录：`/home/cqc/pixelpad/pixelpad`

```text
pixelpad/
├─ lib/
│  ├─ core/
│  │  ├─ app/          # 应用壳、路由、导航、依赖注入
│  │  ├─ services/     # 跨模块服务（如启动日志）
│  │  ├─ theme/        # 主题与设计令牌
│  │  └─ utils/        # 工具函数
│  └─ features/        # 按业务域组织
│     ├─ auth/
│     ├─ onboarding/
│     ├─ profile/
│     ├─ make/
│     ├─ device/
│     ├─ home/
│     └─ logs/
├─ assets/             # 图片、图标、字体
├─ test/               # 测试（当前较少）
├─ Mock/               # 本地 mock 后端
├─ android/ ios/ web/ macos/ windows/ linux/
└─ pubspec.yaml
```

### 分层特征

- `core/`：框架层（路由、主题、AppScope 注入）
- `features/`：业务层（按模块拆分，不同模块分层深度不同）
- 目前各模块分层现状：
  - `profile`：`data + domain + presentation`
  - `make`：`data + presentation`
  - `device`：`domain + presentation`
  - `auth` / `home` / `onboarding` / `logs`：以 `presentation` 为主

## 3. 启动链路与应用壳

启动链路（`lib/main.dart`）：

1. `WidgetsFlutterBinding.ensureInitialized()`
2. 构建 `AppDependencies`
3. `dependencies.logService.recordLaunch()` 记录启动日志
4. 锁定竖屏：`SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])`
5. `runApp(PixelPadApp(...))`

应用壳（`core/app/app.dart`）：

- `PixelPadApp` 使用 `AppScope` 包裹 `MaterialApp`
- `initialRoute = AppRoutes.splash`
- 统一路由表：`AppRoutes.routes`

## 4. 路由与页面流

路由集中在 `core/app/routes.dart`，主要流转如下：

```text
splash(/)
  -> onboarding/2
  -> onboarding/3
  -> onboarding/4
  -> login
      -> login/phone -> mainShell
      -> register -> profile/guide/intro -> gender -> age -> username -> mainShell

mainShell(/main)
  -> 主页(home)
  -> 图片制作(make)
  -> 设备管理(device)
  -> 个人中心(profile)
```

`MainShell` 采用 `BottomNavigationBar + IndexedStack`，对应 4 个主 Tab（home/make/device/profile）。

## 5. 依赖注入与状态管理

## 5.1 依赖注入

- 机制：`InheritedWidget`（`core/app/app_scope.dart`）
- 容器：`AppDependencies`（`core/app/dependencies.dart`）
- 当前注入对象：
  - `UserRepository`
  - `ProfileRepository`
  - `LogService`

页面通过 `AppScope.of(context)` 获取仓库/服务（例如 `PhoneLoginScreen`、`ProfileScreen`、`LogsScreen`）。

## 5.2 状态管理

当前项目未引入 Provider/BLoC/Riverpod 等统一状态框架，主要依赖：

- `StatefulWidget + setState`
- `FutureBuilder`（如日志页）
- 局部控制器（`AnimationController`、`PageController`）

结论：当前属于“轻量本地状态 + 手动依赖注入”架构。

## 6. 数据流认知（按模块）

## 6.1 认证与用户资料（`features/auth` + `features/profile`）

- `UserRepository` 对外提供：`login/register/fetchCurrentUser/saveCurrentUser/logout`
- `MockBackendDataSource` 通过 `http` 访问后端：
  - `POST /login`
  - `POST /register`
  - `GET/PUT /users/{id}`
- 登录态持久化：`SharedPreferences`，键为 `current_user_id_v1`
- 个人中心与编辑页读取/更新 `UserProfile`

数据流：

```text
UI(Screen)
  -> UserRepository
    -> UserDataSource(MockBackendDataSource)
      -> HTTP API / SharedPreferences(session user id)
```

## 6.2 图片制作（`features/make`）

- 图源：相册（`image_picker`）或 assets 内置图库
- 编辑：`image_editor`（裁剪/缩放/滤镜）
- 后端处理：
  - `POST {makeApiBaseUrl}/process` 上传图片与预设
  - `POST {makeApiBaseUrl}/render` 拉取渲染图
- `makeApiBaseUrl` 当前常量：`http://backend.edmounds.top`
- 豆子预设存储：`BeanPresetStorage`（`SharedPreferences`）
  - `bean_preset_brand`
  - `bean_preset_count`

## 6.3 启动日志（`features/logs` + `core/services/log_service.dart`）

- 启动时写入：`recordLaunch()`
- 查看页读取：`getLogs()`
- 存储键：`launch_logs`（`SharedPreferences StringList`）

## 6.4 设备模块（`features/device`）

- 当前使用 `DeviceData.sample()` 的本地示例数据
- 文件内已有 TODO：后续替换为 repository/provider 驱动

## 7. 主题与设计系统

- `core/theme/app_theme.dart` 提供：
  - `AppColors`（全局颜色）
  - `AppTheme.light()`（基于深色 ColorScheme 定制）
  - `AppTextStyles`（统一字体样式）
- 字体在 `pubspec.yaml` 注册（Geometos / Outfit / OPPO Sans 4.0）

## 8. 测试与工程质量现状

- 测试目录：`test/`
- 当前仅有一个基础 widget 测试：`test/widget_test.dart`
  - 校验 `PixelPadApp` 能构建 `MaterialApp`
- 常用命令（`pixelpad/README.md` 提供）：
  - `flutter pub get`
  - `flutter run`
  - `flutter analyze`
  - `flutter test`

## 9. 当前架构特征总结

1. **架构形态**：Feature-first + 轻量分层（core/features），局部 data/domain/presentation。
2. **依赖管理**：`AppScope + AppDependencies` 手动注入，结构清晰但扩展性受限于手工维护。
3. **状态管理**：以页面局部状态为主，适合当前规模；跨页/复杂状态场景可能逐步需要统一方案。
4. **数据来源**：网络（mock backend）与本地持久化（SharedPreferences）并存。
5. **成熟度**：功能开发中，部分模块（如 device）仍为演示数据；测试覆盖较薄。

## 10. 认知中的关键注意点

- `AppDependencies` 中已注入 `ProfileRepository`，但当前未看到页面链路对其进行读取或调用（目前主要使用 `UserRepository`）。
- `makeApiBaseUrl` 固定为 `backend.edmounds.top`，真机或不同环境需显式切换。
- 目前路由为静态 `routes` 映射，尚未看到集中式鉴权守卫（通过页面内逻辑处理登录态）。
