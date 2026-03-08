# 前端页面 × 后端接口快速定位指导

## 1. 目标

让后续需求可以直接按「页面 + 接口 + 目标行为」落地，减少反复沟通，实现快速定位与开发。

---

## 2. 当前仓库前端基线（已确认）

### 2.1 双前端现状

- 小程序端：`/miniprogram`
- Flutter 主应用：`/pixelpad`

### 2.2 小程序定位锚点

- 路由入口：`miniprogram/miniprogram/app.json`
- 启动逻辑：`miniprogram/miniprogram/app.ts`
- 关键点：当前仅见 `wx.login`，尚未发现业务后端 HTTP 调用层（未见 `wx.request` 业务接入代码）

### 2.3 Flutter 定位锚点

- 路由定义：`pixelpad/lib/core/app/routes.dart`
- 主 Tab 映射：`pixelpad/lib/core/app/main_shell_tabs.dart`
- 当前后端接口接入点（核心）：
  - `pixelpad/lib/features/make/presentation/screens/make_screen.dart`（`POST /process`）
  - `pixelpad/lib/features/make/presentation/screens/make_result_screen.dart`（`POST /render`）
  - `pixelpad/lib/features/profile/data/user_repository.dart`（`/login`、`/register`、`/users/{id}`）

### 2.4 OpenAPI 现状

- 当前仓库内尚未发现现成的 OpenAPI codegen 流水线配置或生成产物。

---

## 3. 一次性资料包（建议你先提供）

为了后续我能“秒定位 + 秒开发”，建议一次性提供以下信息：

1. OpenAPI 文档（JSON / YAML / URL）
2. 环境基址（dev / test / prod）
3. 鉴权规则（Header、Token、刷新机制）
4. 错误码与前端策略（toast、重试、跳登录等）
5. 本次需求优先客户端（Flutter 或 Miniprogram）

---

## 4. 后续每次提需求的标准模板（直接复制）

```text
端: Flutter | Miniprogram
页面: 路由名/页面路径（不知道可描述页面位置）
功能: 目标行为（含成功态与失败态）
接口: operationId 或 METHOD /path
入参映射: UI字段 -> API字段
完成标准: 你如何验收算完成
```

---

## 5. 我收到需求后的执行流程（固定）

1. 先确认客户端（Flutter/Miniprogram）
2. 从路由锚点定位页面文件
3. 从现有数据层锚点定位接口接线位置
4. 实现 UI 交互、请求、状态与异常处理
5. 本地验证并回传「改动文件清单 + 验证结果」

---

## 6. 当前关键约束

- 若需求目标是 **Miniprogram 接后端接口**：通常需要先补一层统一请求封装（基于 `wx.request`）再接业务页面。
- 若需求目标是 **Flutter**：当前已有可复用的数据接入样式，可直接按现有模式扩展。

---

## 7. 推荐下一步

直接发你的第一个功能需求，并按模板给出：

- 客户端
- 页面
- 接口
- 完成标准

我会直接给出「实现文件清单 + 具体改动方案 + 落地代码」。
