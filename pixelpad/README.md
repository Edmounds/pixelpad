# PixelPad

PixelPad 是一款面向移动端的像素艺术/拼豆作品制作应用，提供从素材导入、像素化处理到颜色统计与成品预览的一体化创作流程。当前项目仍在持续开发中，文档与功能会随迭代更新。

## 项目定位

- 面向移动端的主应用（Flutter）
- 支持本地创作与后端交互

## 功能概览

- 新手引导与登录/注册
- 图片制作：上传图片或文本生成像素图纸
- 拼豆预设：选择品牌与颜色数量
- 像素管理与创作数据查看
- 个人资料编辑与用户档案
- 启动日志查看

## 技术栈与依赖

- Flutter / Dart
- http
- shared_preferences
- image_picker
- image_editor
- flutter_svg

## 目录结构

- `lib/`：主应用代码
  - `core/`：应用壳、路由、主题、依赖注入
  - `features/`：按功能模块组织
- `assets/`：图片、图标等资源
- `Mock/`：本地 Mock 后端与数据
- `test/`：测试
- `android/`、`ios/`、`web/`、`windows/`、`macos/`、`linux/`：多端工程

## 环境要求

- Flutter SDK 3.10.x（项目使用 Dart ^3.10.8）
- Android Studio / Xcode（按目标平台配置）

## 快速开始

使用Android Studio启动模拟器，选择默认虚拟机。

```bash
flutter pub get
flutter run
```

## Mock 后端

项目内置一个简单的本地 Mock 服务，用于登录/注册与图纸处理流程演示。

```bash
python Mock/mock_backend.py
```

默认监听：`0.0.0.0:8080`。

客户端默认请求地址：
- `lib/features/make/data/make_api.dart`
- `lib/features/profile/data/user_repository.dart`

Android 模拟器使用 `backend.edmounds.top` 访问宿主机；真机调试请改为你的本机局域网 IP。

Mock 账号（预置）：
- 手机号：`13800000000`
- 密码：`123456`

实际测试时，请启动Backend真实后端测试，参考项目测试Mock编写，注意修改项目内的后端IP。

## 打包发布

略

## 测试

### 1) 单元/组件测试

```bash
flutter test
```

### 2) 代码静态检查

```bash
flutter analyze
```

### 3) 模拟后端联调（可选）

```bash
python Mock/mock_backend.py
```

确保 App 端请求地址指向本机 Mock 服务：
- Android 模拟器：`backend.edmounds.top`
- 真机：替换为本机局域网 IP

## 许可证

见 `LICENSE`。

© 2026 Yang Dirui. All rights reserved.
