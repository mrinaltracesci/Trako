import 'dart:convert';

import 'package:Trako/screens/toner_request/add_request.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:Trako/color/colors.dart';
import 'package:Trako/globals.dart';
import 'package:Trako/network/ApiService.dart';
import 'package:flutter/services.dart';
import '../../model/supply_fields_data.dart';
import '../../utils/popup_radio_checkbox.dart';

class AddModel extends StatefulWidget {
  final Map<String, dynamic>? machineData;
  const AddModel({super.key, this.machineData});

  @override
  State<AddModel> createState() => _AddModelState();
}

class _AddModelState extends State<AddModel> {
  final TextEditingController machine_name_Controller = TextEditingController();
  final List<TextEditingController> colorControllers = [TextEditingController()];
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  List<SupplyClient> clients = [];
  bool activeChecked = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();

    if (widget.machineData != null) {
      machine_name_Controller.text = widget.machineData!['model_no'] ?? '';

      if (widget.machineData!['color_name'] != null) {
        colorControllers.clear();

        List<String> colorsList = [];
        dynamic colorNamesInput = widget.machineData!['color_name'];

        try {
          if (colorNamesInput is List) {
            colorsList = colorNamesInput.map((item) => item.toString()).toList();
          } else if (colorNamesInput is String && colorNamesInput.isNotEmpty) {
            List<dynamic> parsed = jsonDecode(colorNamesInput);
            colorsList = parsed.map((item) => item.toString()).toList();
          }
        } catch (e) {
          print('Error parsing color names in initState: $e');
        }

        if (colorsList.isNotEmpty) {
          for (var color in colorsList) {
            colorControllers.add(TextEditingController(text: color.trim()));
          }
        } else {
          colorControllers.add(TextEditingController());
        }
      }

      if (widget.machineData!['isActive'] is int) {
        activeChecked = widget.machineData!['isActive'] == 1;
      } else if (widget.machineData!['isActive'] is bool) {
        activeChecked = !widget.machineData!['isActive'];
      }
    }

    // Add listeners to enable/disable submit button
    machine_name_Controller.addListener(() => setState(() {}));
    for (var controller in colorControllers) {
      controller.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    machine_name_Controller.dispose();
    for (var controller in colorControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  // Check if form is valid
  bool get isFormValid {
    final hasModelName = machine_name_Controller.text.trim().isNotEmpty;
    final hasValidColor = colorControllers.any((c) => c.text.trim().isNotEmpty);
    return hasModelName && hasValidColor;
  }

  void addColorField() {
    final lastColor = colorControllers.last.text.trim();

    if (lastColor.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Please fill the current color field before adding a new one."),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (colorControllers.length >= 20) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Maximum 20 colors allowed."),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      colorControllers.add(TextEditingController());
      colorControllers.last.addListener(() => setState(() {}));
    });
  }

  void removeColorField(int index) {
    if (colorControllers.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("At least one color field is required."),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      TextEditingController controller = colorControllers.removeAt(index);
      controller.dispose();
    });
  }

  List<String> getColorsList() {
    return colorControllers
        .where((controller) => controller.text.trim().isNotEmpty)
        .map((controller) => controller.text.trim())
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (machine_name_Controller.text.isNotEmpty ||
            colorControllers.any((c) => c.text.isNotEmpty)) {
          return await _showUnsavedChangesDialog() ?? false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Image.asset(
            "assets/images/ic_trako.png",
            width: 120,
            height: 40,
          ),
          actions: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: IconButton(
                icon: const Icon(Icons.person),
                onPressed: () {
                  Navigator.pushNamed(context, '/profile');
                },
              ),
            ),
            const SizedBox(width: 7),
          ],
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 26.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  Center(
                    child: Text(
                      widget.machineData != null ? "Update Model:" : "Add New Model:",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24.0,
                        color: colorMixGrad,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Model Name Section
                  const Text(
                    "Model Name",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  CustomTextField(
                    controller: machine_name_Controller,
                    hintText: 'Enter model name',
                  ),
                  if (machine_name_Controller.text.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6.0),
                      child: Text(
                        "Model name is required",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red.withOpacity(0.8),
                        ),
                      ),
                    ),
                  const SizedBox(height: 28),

                  // Colors Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Colors",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "${getColorsList().length} added",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),

                  // Dynamic list of color fields
                  ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: colorControllers.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Row(
                          children: [
                            // Color number indicator
                            Container(
                              width: 32,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(6),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                "${index + 1}",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: CustomTextField(
                                controller: colorControllers[index],
                                hintText: 'Enter color name',
                              ),
                            ),
                            SizedBox(width: 8),
                            // Delete button with confirmation
                            if (colorControllers.length > 1)
                              GestureDetector(
                                onTap: () => _showDeleteColorConfirmation(index),
                                child: Container(
                                  width: 44,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: Colors.red.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                ),
                              )
                            else
                              SizedBox(width: 44),
                          ],
                        ),
                      );
                    },
                  ),

                  if (getColorsList().isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        "At least one color is required",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red.withOpacity(0.8),
                        ),
                      ),
                    ),

                  // Add new color button
                  Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: AnimatedOpacity(
                        opacity: colorControllers.last.text.trim().isNotEmpty ? 1.0 : 0.6,
                        duration: Duration(milliseconds: 200),
                        child: TextButton.icon(
                          icon: Icon(Icons.add, color: colorMixGrad),
                          label: Text(
                            "Add Color",
                            style: TextStyle(color: colorMixGrad),
                          ),
                          onPressed: colorControllers.last.text.trim().isNotEmpty
                              ? addColorField
                              : null,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 20),

                  // Active/Inactive toggle
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CheckBoxRow(
                        activeChecked: activeChecked,
                        onActiveChanged: (bool? value) {
                          setState(() {
                            activeChecked = value ?? false;
                          });
                        },
                      )
                    ],
                  ),

                  // Submit button with state awareness
                  SizedBox(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 50, right: 50, top: 50),
                      child: AnimatedOpacity(
                        opacity: isFormValid && !_isSubmitting ? 1.0 : 0.5,
                        duration: Duration(milliseconds: 300),
                        child: GradientButton(
                          gradientColors: const [colorFirstGrad, colorSecondGrad],
                          height: 45.0,
                          width: 10.0,
                          radius: 25.0,
                          buttonText: _isSubmitting ? "Submitting..." : "Submit",
                          onPressed: () {
                            if (isFormValid && !_isSubmitting) {
                              validateAndSignIn();
                            }
                          },
                        ),

                      ),
                    ),
                  ),
                  const SizedBox(height: 100)
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> validateAndSignIn() async {
    if (machine_name_Controller.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Please enter a model name"),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    List<String> colorsList = getColorsList();
    if (colorsList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Please add at least one color"),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show confirmation with summary
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Confirm Details"),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Model Name: ${machine_name_Controller.text.trim()}",
                  style: TextStyle(fontSize: 14),
                ),
                SizedBox(height: 12),
                Text(
                  "Colors (${colorsList.length}):",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 8),
                ...colorsList.asMap().entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 16.0, bottom: 6),
                    child: Text("• ${entry.value}", style: TextStyle(fontSize: 13)),
                  );
                }).toList(),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                addMachine();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colorMixGrad,
              ),
              child: Text("Confirm", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteColorConfirmation(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Remove Color"),
          content: Text("Are you sure you want to remove '${colorControllers[index].text}'?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                removeColorField(index);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text("Remove", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<bool?> _showUnsavedChangesDialog() {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Unsaved Changes"),
          content: Text("You have unsaved changes. Do you want to leave?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text("Stay"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text("Leave", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> addMachine() async {
    setState(() => _isSubmitting = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  widget.machineData != null ? "Updating..." : "Adding...",
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        );
      },
    );

    List<String> colorsList = getColorsList();

    try {
      final ApiService apiService = ApiService();

      final addMachineResponse = await apiService.addMachineModel(
        id: widget.machineData != null ? widget.machineData!['id'].toString() : null,
        model_no: machine_name_Controller.text.trim(),
        colors: colorsList,
        isActive: activeChecked,
      );

      Navigator.of(context).pop(); // Dismiss loading dialog

      if (addMachineResponse.containsKey('error') &&
          addMachineResponse.containsKey('status')) {
        if (!addMachineResponse['error'] &&
            addMachineResponse['status'] == 200) {
          if (addMachineResponse['message'] == 'Success') {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(widget.machineData != null
                    ? "Model updated successfully!"
                    : "Model added successfully!"),
                duration: Duration(seconds: 2),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );

            machine_name_Controller.clear();
            for (var controller in colorControllers) {
              controller.clear();
            }
            while (colorControllers.length > 1) {
              TextEditingController controller = colorControllers.removeLast();
              controller.dispose();
            }

            Future.delayed(Duration(milliseconds: 500), () {
              Navigator.pop(context, true);
            });
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(addMachineResponse['message']),
                backgroundColor: Colors.orange,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(addMachineResponse['message']),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Unexpected response from server. Please try again."),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      Navigator.of(context).pop(); // Dismiss loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Connection failed. Please try again."),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      print("Add Machine API Error: $e");
    } finally {
      setState(() => _isSubmitting = false);
    }
  }
}