import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const PasswordManagerApp());
}

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  _LockScreenState createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final TextEditingController passcodeController = TextEditingController();

  void unlockApp() {
    String passcode = passcodeController.text;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => HomeScreen(passcode: passcode),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF252525),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Enter Passcode',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 200,
              child: TextField(
                controller: passcodeController,
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: 'Passcode',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: unlockApp,
              child: const Text('Unlock'),
            ),
          ],
        ),
      ),
    );
  }
}

class PasswordManagerApp extends StatelessWidget {
  const PasswordManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const LockScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final String passcode;

  const HomeScreen({super.key, required this.passcode});

  @override
  _HomescreenState createState() => _HomescreenState();
}

class _HomescreenState extends State<HomeScreen> {
  List<String> websites = [];

  @override
  void initState() {
    super.initState();
    authenticatePasscode().then((_) {
      fetchWebsites();
    });
  }

  Future<void> authenticatePasscode() async {
    try {
      final response = await http.post(
        Uri.parse('http://localhost:5000/authenticate'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'passcode': widget.passcode}),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Authenticated: ${result['message']}')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Authentication failed.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> fetchWebsites() async {
    try {
      final response =
          await http.get(Uri.parse('http://localhost:5000/get-websites'));
      if (response.statusCode == 200) {
        setState(() {
          websites = List<String>.from(json.decode(response.body)['websites']);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to fetch websites.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> searchPassword(String website) async {
    final response = await http.get(
        Uri.parse('http://localhost:5000/search-password?website=$website'));
    if (response.statusCode == 200) {
      final result = json.decode(response.body);
      String password = result['password'];
      String user = result['user'];

      ScaffoldMessenger.of(context).removeCurrentSnackBar();

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
        'User: $user\nPassword: $password',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      )));
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Website not found.')),
        );
      }
    }
  }

  Future<void> deletePassword(String website) async {
    final response = await http.post(
        Uri.parse('http://localhost:5000/delete-password?website=$website'));
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password deleted.')),
      );
      fetchWebsites();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Website not found.')),
        );
      }
    }
  }

  Future<void> updatePassword(String website, String newPassword) async {
    final response = await http.post(
      Uri.parse('http://localhost:5000/edit-password'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'website': website,
        'new_password': newPassword,
      }),
    );
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated successfully!')),
      );
      fetchWebsites();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update the password.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: const Color(0xFF252525),
        appBar: AppBar(
          title: const Text('Home'),
          backgroundColor: const Color(0xFF252525),
          foregroundColor: const Color(0xFFdbdbdb),
          actions: [
            IconButton(
              icon: const Icon(Icons.add, color: Color(0xFFdbdbdb)),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        PasswordManagerScreen(onSave: fetchWebsites),
                  ),
                );
              },
            ),
          ],
        ),
        body: websites.isEmpty
            ? const Center(
                child: Text(
                  'No passwords found. Tap the "+" button to add one.',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              )
            : Center(
                child: Container(
                width: MediaQuery.of(context).size.width * 0.7,
                child: ListView.builder(
                  itemCount: websites.length,
                  itemBuilder: (context, index) {
                    return Card(
                      color: const Color(0xFF353535),
                      child: ListTile(
                        title: Text(
                          websites[index],
                          style: const TextStyle(color: Color(0xFFdbdbdb)),
                        ),
                        onTap: () async {
                          // view/edit/delete
                          await _showActionSheet(context, websites[index]);
                        },
                      ),
                    );
                  },
                ),
              )));
  }

  Future<void> _showActionSheet(BuildContext context, String website) async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.visibility),
              title: const Text('View'),
              onTap: () async {
                Navigator.pop(context);
                await searchPassword(website);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit'),
              onTap: () async {
                Navigator.pop(context);
                await _showEditSheet(context, website);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Delete'),
              onTap: () async {
                Navigator.pop(context);
                await deletePassword(website);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showEditSheet(BuildContext context, String website) async {
    TextEditingController newPasswordController = TextEditingController();
    TextEditingController confirmPasswordController = TextEditingController();

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Wrap(
          children: [
            TextField(
              controller: newPasswordController,
              decoration: const InputDecoration(
                labelText: 'New Password',
                prefixIcon: Icon(Icons.lock),
              ),
              obscureText: true,
            ),
            TextField(
              controller: confirmPasswordController,
              decoration: const InputDecoration(
                labelText: 'Confirm New Password',
                prefixIcon: Icon(Icons.lock),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                if (newPasswordController.text ==
                    confirmPasswordController.text) {
                  Navigator.pop(context);
                  await updatePassword(website, newPasswordController.text);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Passwords do not match.')),
                  );
                }
              },
              child: const Text('Change Password'),
            ),
          ],
        );
      },
    );
  }
}

class PasswordManagerScreen extends StatefulWidget {
  final VoidCallback onSave;
  const PasswordManagerScreen({super.key, required this.onSave});

  @override
  _PasswordManagerScreenState createState() => _PasswordManagerScreenState();
}

class _PasswordManagerScreenState extends State<PasswordManagerScreen> {
  final TextEditingController websiteController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController letter_countController = TextEditingController();
  final TextEditingController symbol_countController = TextEditingController();
  final TextEditingController number_countController = TextEditingController();
  String searchResult = '';
  bool isAdvancedSettingsVisible = false;

  Future<void> generatePassword() async {
    if (letter_countController.text != "") {
      final response = await http.post(
          Uri.parse('http://localhost:5000/generate-password-adv'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'letter_count': letter_countController.text,
            'symbol_count': symbol_countController.text,
            'number_count': number_countController.text
          }));
      if (response.statusCode == 200) {
        setState(() {
          passwordController.text = json.decode(response.body)['password'];

          letter_countController.clear();
          symbol_countController.clear();
          number_countController.clear();
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to generate password.')),
          );
        }
      }
    } else {
      final response =
          await http.get(Uri.parse('http://localhost:5000/generate-password'));
      if (response.statusCode == 200) {
        setState(() {
          passwordController.text = json.decode(response.body)['password'];
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to generate password.')),
          );
        }
      }
    }
  }

  Future<void> advancedSettings() async {
    setState(() {
      isAdvancedSettingsVisible = !isAdvancedSettingsVisible;
    });
  }

  Future<void> savePassword() async {
    final response =
        await http.post(Uri.parse('http://localhost:5000/save-password'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'website': websiteController.text,
              'user': emailController.text,
              'password': passwordController.text
            }));
    if (response.statusCode == 200) {
      if (mounted) {
        websiteController.clear();
        emailController.clear();
        passwordController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password saved successfully!')),
        );
        widget.onSave();
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save password.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF252525),
      appBar: AppBar(
        title: const Text('Add Password'),
        centerTitle: true,
        backgroundColor: Color(0xFF252525),
        foregroundColor: Color(0xFFdbdbdb),
      ),
      body: SingleChildScrollView(
        child: Padding(
            padding: const EdgeInsets.all(70.0),
            child: Column(children: [
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Expanded(
                              child: TextField(
                                controller: websiteController,
                                decoration: const InputDecoration(
                                  labelText: 'Website',
                                  labelStyle:
                                      TextStyle(color: Color(0xFFdbdbdb)),
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.web),
                                ),
                              ),
                            ),
                          ]),
                      const SizedBox(height: 12),
                      TextField(
                        controller: emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email/Username',
                          labelStyle: TextStyle(color: Color(0xFFdbdbdb)),
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: TextField(
                              controller: passwordController,
                              decoration: const InputDecoration(
                                labelText: 'Password',
                                labelStyle: TextStyle(color: Color(0xFFdbdbdb)),
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.lock),
                              ),
                              obscureText: true,
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: isAdvancedSettingsVisible
                                ? () {
                                    generatePassword();
                                    advancedSettings();
                                  }
                                : generatePassword,
                            icon: const Icon(Icons.vpn_key),
                            label: const Text('Generate Password'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              backgroundColor: Color(0xFF252525),
                              foregroundColor: Color(0xFFdbdbdb),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton.icon(
                            onPressed: savePassword,
                            icon: const Icon(Icons.save),
                            label: const Text('Save Password'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              backgroundColor: Color(0xFF252525),
                              foregroundColor: Color(0xFFdbdbdb),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: advancedSettings,
                            icon: const Icon(Icons.settings),
                            label: const Text('Advanced'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              backgroundColor: Color(0xFF252525),
                              foregroundColor: Color(0xFFdbdbdb),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        searchResult,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (isAdvancedSettingsVisible)
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 20),
                        TextField(
                          controller: letter_countController,
                          decoration: const InputDecoration(
                            labelText: 'number of letters',
                            labelStyle: TextStyle(color: Color(0xFFdbdbdb)),
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.abc),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: symbol_countController,
                          decoration: const InputDecoration(
                            labelText: 'number of symbols',
                            labelStyle: TextStyle(color: Color(0xFFdbdbdb)),
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.emoji_symbols),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: number_countController,
                          decoration: const InputDecoration(
                            labelText: 'number of numbers',
                            labelStyle: TextStyle(color: Color(0xFFdbdbdb)),
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.functions),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ])),
      ),
    );
  }
}
