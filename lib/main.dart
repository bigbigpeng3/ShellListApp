import 'package:flutter/material.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:process_run/shell.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '分类列表App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: CategoryListPage(),
    );
  }
}

class Category {
  String name;
  List<Item> items;

  Category({required this.name, required this.items});

  Map<String, dynamic> toJson() => {
        'name': name,
        'items': items.map((item) => item.toJson()).toList(),
      };

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      name: json['name'],
      items:
          (json['items'] as List).map((item) => Item.fromJson(item)).toList(),
    );
  }
}

class Item {
  String title;
  String command;
  bool openInTerminal;

  Item({required this.title, required this.command, this.openInTerminal = false});

  Map<String, dynamic> toJson() => {
    'title': title,
    'command': command,
    'openInTerminal': openInTerminal,
  };

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      title: json['title'],
      command: json['command'],
      openInTerminal: json['openInTerminal'] ?? false,
    );
  }

  // 添加 copyWith 方法
  Item copyWith({String? title, String? command, bool? openInTerminal}) {
    return Item(
      title: title ?? this.title,
      command: command ?? this.command,
      openInTerminal: openInTerminal ?? this.openInTerminal,
    );
  }
}

class CategoryListPage extends StatefulWidget {
  @override
  _CategoryListPageState createState() => _CategoryListPageState();
}

class _CategoryListPageState extends State<CategoryListPage> {
  // List<String> categories = ['分类1', '分类2', '分类3', '分类4'];
  // String selectedCategory = '分类1';

  List<Category> categories = [];
  String selectedCategory = '';

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final String? categoriesJson = prefs.getString('categories');
    if (categoriesJson != null) {
      final List<dynamic> decodedCategories = jsonDecode(categoriesJson);
      setState(() {
        categories = decodedCategories.map((cat) => Category.fromJson(cat)).toList();
      });
    } else {
      // 如果没有保存的数据，创建默认分类和项目
      setState(() {
        categories = [
          Category(
            name: 'Category',
            items: [
              Item(
                title: 'Sample',
                command: 'echo Hello, World!',
              ),
            ],
          ),
        ];
      });
      // 保存默认数据
      _saveCategories();
    }

    // 设置选中的分类
    if (categories.isNotEmpty) {
      selectedCategory = categories[0].name;
    } else {
      // 如果categories为空，添加一个默认分类
      categories.add(Category(name: 'Category', items: []));
      selectedCategory = 'Category';
      _saveCategories();
    }
  }

  Future<void> _saveCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedCategories = jsonEncode(categories);
    await prefs.setString('categories', encodedCategories);
  }

  void _addCategory() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String newCategoryName = '';
        return AlertDialog(
          title: Text('添加新分类'),
          content: TextField(
            onChanged: (value) {
              newCategoryName = value;
            },
            decoration: InputDecoration(hintText: "输入分类名称"),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('取消'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: Text('添加'),
              onPressed: () {
                if (newCategoryName.isNotEmpty) {
                  setState(() {
                    categories.add(Category(
                      name: newCategoryName,
                      items: [
                        Item(
                          title: '默认项目',
                          command: 'echo "这是一个新分类的默认项目"',
                        ),
                      ],
                    ));
                    selectedCategory = newCategoryName;
                  });
                  _saveCategories();
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _deleteCategory(Category category) {
    setState(() {
      categories.remove(category);
      if (categories.isEmpty) {
        categories.add(Category(name: 'Default', items: []));
      }
      selectedCategory = categories[0].name;
    });
    _saveCategories();
  }

  void _editCategory(Category category) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String newCategoryName = category.name;
        return AlertDialog(
          title: Text('编辑分类名称'),
          content: TextField(
            onChanged: (value) {
              newCategoryName = value;
            },
            decoration: InputDecoration(hintText: "输入新的分类名称"),
            controller: TextEditingController(text: category.name),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('取消'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: Text('保存'),
              onPressed: () {
                if (newCategoryName.isNotEmpty && newCategoryName != category.name) {
                  setState(() {
                    category.name = newCategoryName;
                    if (selectedCategory == category.name) {
                      selectedCategory = newCategoryName;
                    }
                  });
                  _saveCategories();
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _addItem(Category category) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String newItemTitle = '';
        String newItemCommand = '';
        bool openInTerminal = false;
        return AlertDialog(
          title: Text('添加新项目'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                onChanged: (value) {
                  newItemTitle = value;
                },
                decoration: InputDecoration(hintText: "输入项目标题"),
              ),
              TextField(
                onChanged: (value) {
                  newItemCommand = value;
                },
                decoration: InputDecoration(hintText: "输入执行命令"),
              ),
              Row(
                children: [
                  Checkbox(
                    value: openInTerminal,
                    onChanged: (bool? value) {
                      setState(() {
                        openInTerminal = value ?? false;
                      });
                    },
                  ),
                  Text('在终端中打开'),
                ],
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text('取消'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: Text('添加'),
              onPressed: () {
                if (newItemTitle.isNotEmpty && newItemCommand.isNotEmpty) {
                  setState(() {
                    category.items.add(
                      Item(
                        title: newItemTitle,
                        command: newItemCommand,
                        openInTerminal: openInTerminal,
                      ),
                    );
                  });
                  _saveCategories();
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _deleteItem(Category category, Item item) {
    setState(() {
      category.items.remove(item);
    });
    _saveCategories();
  }

  void _updateItem(Category category, int itemIndex, Item newItem) {
    setState(() {
      category.items[itemIndex] = newItem;
    });
    _saveCategories();
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final Category item = categories.removeAt(oldIndex);
      categories.insert(newIndex, item);
    });
    _saveCategories();
  }

  void _onReorderItems(Category category, int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final Item item = category.items.removeAt(oldIndex);
      category.items.insert(newIndex, item);
    });
    _saveCategories();
  }


  Future<void> exportData() async {
    try {
      final String jsonData = jsonEncode({
        'categories': categories.map((c) => c.toJson()).toList(),
      });

      // final directory = await getApplicationDocumentsDirectory();
      final directory = await getDownloadsDirectory();
      final file = File('${directory?.path}/categories_backup.json');
      await file.writeAsString(jsonData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('数据已成功导出到: ${file.path}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('导出失败: $e')),
      );
    }
  }

  Future<void> importData() async {
    try {
      // 先保存当前数据
      await _saveCategories();

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null) {
        File file = File(result.files.single.path!);
        String jsonString = await file.readAsString();
        Map<String, dynamic> jsonData = jsonDecode(jsonString);

        setState(() {
          categories = (jsonData['categories'] as List)
              .map((cat) => Category.fromJson(cat))
              .toList();
        });

        await _saveCategories();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('数据已成功导入')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('导入失败: $e')),
      );
    }
  }

  void _editItem(Category category, Item item) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String newItemTitle = item.title;
        String newItemCommand = item.command;
        bool openInTerminal = item.openInTerminal;
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text('编辑项目'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    onChanged: (value) {
                      newItemTitle = value;
                    },
                    decoration: InputDecoration(hintText: "输入项目标题"),
                    controller: TextEditingController(text: item.title),
                  ),
                  TextField(
                    onChanged: (value) {
                      newItemCommand = value;
                    },
                    decoration: InputDecoration(hintText: "输入执行命令"),
                    controller: TextEditingController(text: item.command),
                  ),
                  Row(
                    children: [
                      Checkbox(
                        value: openInTerminal,
                        onChanged: (bool? value) {
                          setState(() {
                            openInTerminal = value ?? false;
                          });
                        },
                      ),
                      Text('在终端中打开'),
                    ],
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('取消'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                ElevatedButton(
                  child: Text('保存'),
                  onPressed: () {
                    if (newItemTitle.isNotEmpty && newItemCommand.isNotEmpty) {
                      // setState(() {  // 使用父组件的 setState
                      //   int index = category.items.indexOf(item);
                      //   category.items[index] = Item(
                      //     title: newItemTitle,
                      //     command: newItemCommand,
                      //     openInTerminal: openInTerminal,
                      //   );
                      // });
                      // _saveCategories();
                      int index = category.items.indexOf(item);
                      Item newItem = Item(
                        title: newItemTitle,
                        command: newItemCommand,
                        openInTerminal: openInTerminal,
                      );
                      _updateItem(category, index, newItem);
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _executeCommand(Item item) async {
    String command = item.command;
    final RegExp paramRegex = RegExp(r'\$(\w+)');
    final matches = paramRegex.allMatches(command);

    if (matches.isNotEmpty) {
      // 如果命令中包含参数，显示输入对话框
      final Map<String, String>? params = await showDialog<Map<String, String>>(
        context: context,
        builder: (BuildContext context) {
          final Map<String, TextEditingController> controllers = {};
          for (final match in matches) {
            controllers[match.group(1)!] = TextEditingController();
          }

          return AlertDialog(
            title: Text('输入参数'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: controllers.entries.map((entry) {
                  return TextField(
                    controller: entry.value,
                    decoration: InputDecoration(labelText: entry.key),
                  );
                }).toList(),
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: Text('取消'),
                onPressed: () => Navigator.of(context).pop(),
              ),
              ElevatedButton(
                child: Text('执行'),
                onPressed: () {
                  Navigator.of(context).pop(
                    Map.fromEntries(controllers.entries.map(
                          (entry) => MapEntry(entry.key, entry.value.text),
                    )),
                  );
                },
              ),
            ],
          );
        },
      );

      if (params != null) {
        // 替换命令中的参数
        String finalCommand = command;
        params.forEach((key, value) {
          finalCommand = finalCommand.replaceAll('\$$key', value);
        });
        // 执行最终的命令
        if (item.openInTerminal) {
          _openTerminal(item.command);
        } else {
          // 原有的执行逻辑
          _executeShellCommand(item.command);
        }
      }
    } else {
      if (item.openInTerminal) {
        _openTerminal(item.command);
      } else {
        // 原有的执行逻辑
        _executeShellCommand(item.command);
      }
    }
  }

  Future<void> _executeShellCommand(String command) async {
    var shell = Shell();
    var result = await shell.run(command);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('命令执行结果'),
          content: Text(result.outText),
          actions: <Widget>[
            TextButton(
              child: Text('确定'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _openTerminal(String command) async {
    print(command);
    // + "\'"
    var finalCommand = "osascript -e 'tell application " +
        '"Terminal"' +
        ' to do script ' +
        "\"" +
        command +
        "\"" +
        "\'";
    // var finalCommand = "'tell application " + '"Terminal"' + ' to do script ' + "\"" + command + "\"" + "\'";
    var shell = Shell();
    shell.run(finalCommand);
    // final url = 'terminal://$command';
    // if (await canLaunch(url)) {
    //   await launch(url);
    // } else {
    //   throw '无法打开终端';
    // }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: Text('分类列表'),
      // ),
      appBar: AppBar(
        title: Text('Category'),
        actions: [
          IconButton(
            icon: Icon(Icons.file_upload),
            onPressed: exportData,
            tooltip: '导出数据',
          ),
          IconButton(
            icon: Icon(Icons.file_download),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text('导入数据'),
                    content: Text('导入将覆盖现有数据。请确保您已保存当前数据。是否继续？'),
                    actions: <Widget>[
                      TextButton(
                        child: Text('取消'),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      ElevatedButton(
                        child: Text('继续'),
                        onPressed: () {
                          Navigator.of(context).pop();
                          importData();
                        },
                      ),
                    ],
                  );
                },
              );
            },
            tooltip: '导入数据',
          ),
        ],
      ),
      body: Row(
        children: [
          CategoryListWidget(
            categories: categories,
            selectedCategory: selectedCategory,
            onCategorySelected: (category) {
              setState(() {
                selectedCategory = category;
              });
            },
            onAddCategory: _addCategory,
            onDeleteCategory: (category) {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text('确认删除'),
                    content: Text('您确定要删除这个分类吗？这将删除分类中的所有项目。'),
                    actions: <Widget>[
                      TextButton(
                        child: Text('取消'),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      ElevatedButton(
                        child: Text('删除'),
                        onPressed: () {
                          _deleteCategory(category);
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  );
                },
              );
            },
            onEditCategory: _editCategory,
            onReorder: _onReorder,  // 添加这一行
          ),
          Expanded(
            child: categories.isNotEmpty
                ? ItemListWidget(
              category: categories.firstWhere(
                    (cat) => cat.name == selectedCategory,
                orElse: () => categories[0],
              ),
              onAddItem: _addItem,
              onDeleteItem: _deleteItem,
              onExecuteCommand: _executeCommand,
              onReorderItems: _onReorderItems,
              onEditItem: _editItem,
            )
                : Center(child: Text('没有可用的分类')),
          ),
        ],
      ),
    );
  }
}

class CategoryListWidget extends StatelessWidget {
  final List<Category> categories;
  final String selectedCategory;
  final Function(String) onCategorySelected;
  final VoidCallback onAddCategory;
  final Function(Category) onDeleteCategory;
  final Function(Category) onEditCategory;
  final Function(int, int) onReorder;

  CategoryListWidget({
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
    required this.onAddCategory,
    required this.onDeleteCategory,
    required this.onEditCategory,
    required this.onReorder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      color: Colors.grey[200],
      child: Column(
        children: [
          Expanded(
            child: ReorderableListView.builder(
              itemCount: categories.length,
              itemBuilder: (context, index) {
                return Card(
                  key: ValueKey(categories[index]),
                  elevation: 0,
                  color: categories[index].name == selectedCategory
                      ? Colors.blue[100]
                      : null,
                  child: Container(
                    height: 60,
                    padding: EdgeInsets.only(left: 12, right: 32, top: 8, bottom: 8),
                    child: InkWell(
                      onTap: () => onCategorySelected(categories[index].name),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              categories[index].name,
                              style: TextStyle(
                                fontWeight: categories[index].name == selectedCategory
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.edit, size: 20),
                            onPressed: () => onEditCategory(categories[index]),
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints(),
                          ),
                          SizedBox(width: 8),
                          IconButton(
                            icon: Icon(Icons.delete, size: 20),
                            onPressed: () => onDeleteCategory(categories[index]),
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
              onReorder: onReorder,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: onAddCategory,
              child: Text('添加分类'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 36),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ItemListWidget extends StatelessWidget {
  final Category category;
  final Function(Category) onAddItem;
  final Function(Category, Item) onDeleteItem;
  final Function(Item) onExecuteCommand;
  final Function(Category, int, int) onReorderItems;
  final Function(Category, Item) onEditItem;

  ItemListWidget({
    required this.category,
    required this.onAddItem,
    required this.onDeleteItem,
    required this.onExecuteCommand,
    required this.onReorderItems,
    required this.onEditItem,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${category.name} 的项目',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              ElevatedButton(
                onPressed: () => onAddItem(category),
                child: Text('添加项目'),
              ),
            ],
          ),
          SizedBox(height: 16),

          Expanded(
            child: ReorderableListView.builder(
              itemCount: category.items.length,
              itemBuilder: (context, index) {
                final item = category.items[index];
                return
                  Card(
                    key: ValueKey(item),
                    elevation: 2,
                    child: InkWell(
                      onTap: () => onExecuteCommand(item),
                      child: Container(
                        height: 80,
                        padding: EdgeInsets.only(left: 16, right: 0),
                        child: Row(
                          children: [
                            CircleAvatar(
                              child: Text('${index + 1}'),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    item.command,
                                    style: TextStyle(fontSize: 14),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  // SizedBox(height: 4),
                                  Row(
                                    children: [
                                      // Checkbox(
                                      //   value: item.openInTerminal,
                                      //   onChanged: (bool? value) {
                                      //     onEditItem(category, item.copyWith(openInTerminal: value));
                                      //   },
                                      // ),
                                      Text('Open In Terminal: ${item.openInTerminal}'),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // Checkbox(
                            //   value: item.openInTerminal,
                            //   onChanged: (bool? value) {
                            //     onEditItem(category, item.copyWith(openInTerminal: value));
                            //   },
                            // ),
                            IconButton(
                              icon: Icon(Icons.edit),
                              onPressed: () => onEditItem(category, item),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete),
                              onPressed: () => onDeleteItem(category, item),
                              padding: EdgeInsets.zero,
                            ),
                            SizedBox(width: 25),
                          ],
                        ),
                      ),
                    ),
                  );
              },
              onReorder: (oldIndex, newIndex) {
                onReorderItems(category, oldIndex, newIndex);
              },
            ),
          ),
        ],
      ),
    );
  }
}
