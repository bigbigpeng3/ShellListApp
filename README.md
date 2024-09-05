# 分类列表 App

这是一个用Flutter开发的macOS应用程序,用于管理分类和项目列表。用户可以创建多个分类,每个分类下可以添加多个项目,每个项目可以执行特定的命令。

目前只实现了MacOS端，未做国际化，目前用途仅用于自己的工作日常。

![](https://raw.githubusercontent.com/bigbigpeng3/blogimage/main/blogs/ShellListApp.jpg)

## 功能特点

- 创建、编辑和删除分类
- 在每个分类下添加、编辑和删除项目
- 每个项目可以设置标题、执行命令和是否在终端中打开
- 拖拽排序分类和项目
- 数据持久化存储
- 导入/导出功能,支持备份和恢复数据

## 安装

1. 确保您的Mac上安装了Flutter开发环境。如果没有,请参考[Flutter官方文档](https://flutter.dev/docs/get-started/install/macos)进行安装。

2. 克隆此仓库:
   ```
   git clone https://github.com/bigbigpeng3/ShellListApp.git
   ```

3. 进入项目目录:
   ```
   cd ShellListApp
   ```

4. 获取依赖:
   ```
   flutter pub get
   ```

5. 运行应用:
   ```
   flutter run -d macos
   ```

## 使用说明

1. 启动应用后,您将看到主界面,左侧是分类列表,右侧是当前选中分类的项目列表。

2. 点击"添加分类"按钮可以创建新的分类。

3. 选中一个分类后,可以在右侧添加新的项目。

4. 每个项目可以设置标题、执行命令和是否在终端中打开。

5. 点击项目可以执行相应的命令。

6. 使用拖拽可以调整分类和项目的顺序。

7. 点击导出按钮可以将所有数据导出为JSON文件。

8. 点击导入按钮可以从之前导出的JSON文件中恢复数据。
9. 支持参数，使用 $param1 $param2 运行前可以输入参数。 

## 数据导入/导出

- 导出: 点击应用顶部工具栏的导出图标,选择保存位置即可导出所有数据。
- 导入: 点击应用顶部工具栏的导入图标,选择之前导出的JSON文件即可恢复数据。注意,导入操作会覆盖当前的所有数据。

## 开发

本项目使用Flutter开发。如果您想贡献代码,请遵循以下步骤:

1. Fork 本仓库
2. 创建您的特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交您的改动 (`git commit -m 'Add some AmazingFeature'`)
4. 将您的改动推送到分支 (`git push origin feature/AmazingFeature`)
5. 打开一个Pull Request

## 许可证

本项目采用 MIT 许可证。

## 联系方式

如果您有任何问题或建议,请通过以下方式联系我们:

- 项目链接: [https://github.com/bigbigpeng3/ShellListApp](https://github.com/bigbigpeng3/ShellListApp)
- 作者: bigbigpeng
