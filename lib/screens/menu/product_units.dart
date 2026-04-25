// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
//
// import '../../core/utils.dart';
//
// class ProductUnits extends StatefulWidget {
//   const ProductUnits({super.key});
//
//   @override
//   State<ProductUnits> createState() => _ProductUnitsState();
// }
//
// class _ProductUnitsState extends State<ProductUnits> {
//   List<Map> units=[];
//
//   @override
//   void initState() {
//     init();
//     super.initState();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: backGroundColor,
//       body: Row(
//         children: [
//           /// Main Content
//           Expanded(
//             child: Column(
//               children: [
//                 Expanded(
//                   child: Padding(
//                     padding: const EdgeInsets.all(16),
//                     child: categoriesView(context),
//                   ),
//                 )
//               ],
//             ),
//           )
//         ],
//       ),
//     );
//   }
//
//   Widget menuItem(IconData icon, String title, {bool isSelected = false}) {
//     return Container(
//       width: double.infinity,
//       margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
//       decoration: BoxDecoration(
//         color: isSelected ? Colors.deepPurple : Colors.transparent,
//         borderRadius: BorderRadius.circular(8),
//       ),
//       child: ListTile(
//         dense: false,
//         leading: Icon(icon, color: Colors.white),
//         title: Text(title, style: const TextStyle(color: Colors.white)),
//         trailing: isSelected
//             ? const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16)
//             : null,
//       ),
//     );
//   }
//
//   Widget categoriesView(context) {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(10),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.stretch,
//         children: [
//           /// Header
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               const Text(
//                 "Units",
//                 style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
//               ),
//               ElevatedButton(
//                 onPressed: () async{
//                   await showDialog(
//                     context: context,
//                     builder: (context) => const AddCategoryDialog(),
//                   );
//                   init();
//                 },
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.blueGrey,
//                 ),
//                 child: Text("+ Add Unit", style: TextStyle(color: Colors.white)),
//               )
//             ],
//           ),
//
//           const SizedBox(height: 16),
//           Expanded(
//             child: ListView(
//               children: [
//                 // Header Row
//                 Row(
//                   children: const [
//                     Expanded(flex: 0, child: Padding(
//                       padding: EdgeInsets.symmetric(horizontal: 24.0),
//                       child: Text("#",style: TextStyle(),),
//                     )),
//                     Expanded(flex: 4, child: Text("Product Unit")),
//                     Expanded(flex: 1, child: Text("")),
//                   ],
//                 ),
//
//                 const Divider(),
//
//                 // Data Rows
//                 ...List.generate(units.length, (index) {
//                   return Column(
//                     children: [
//                       Row(
//                         children: [
//                           Expanded(
//                             flex: 0,
//                             child: Padding(
//                               padding: EdgeInsets.symmetric(horizontal: 24.0),
//                               child: Text("${index + 1}"),
//                             ),
//                           ),
//                           Expanded(
//                             flex: 4,
//                             child: Text("${units[index]['unit']}"),
//                           ),
//                           Expanded(
//                             flex: 1,
//                             child: PopupMenuButton(
//                               onSelected: (value) async {
//                                 if (value == "delete") {
//                                   FirebaseFirestore.instance
//                                       .collection("product_units")
//                                       .doc(units[index]['id'])
//                                       .delete();
//
//                                   units.removeAt(index);
//                                   setState(() {});
//                                 } else if (value == "edit") {
//                                   await showDialog(
//                                     context: context,
//                                     builder: (context) => AddCategoryDialog(
//                                       data: units[index],
//                                     ),
//                                   );
//                                   init();
//                                 }
//                               },
//                               itemBuilder: (context) => const [
//                                 PopupMenuItem(
//                                     value: "edit", child: Text("Edit")),
//                                 PopupMenuItem(
//                                     value: "delete", child: Text("Delete")),
//                               ],
//                             ),
//                           ),
//                         ],
//                       ),
//                       const Divider(),
//                     ],
//                   );
//                 }),
//               ],
//             ),
//           )
//         ],
//       ),
//     );
//   }
//
//   void init() async{
//     units.clear();
//     var res=await FirebaseFirestore.instance.collection("product_units").get();
//     res.docs.forEach((element) {
//       units.add(element.data());
//     },);
//     if(mounted)
//     setState(() {
//
//     });
//   }
//
//
// }
//
// class AddCategoryDialog extends StatefulWidget {
//   final Map<dynamic, dynamic>? data;
//   const AddCategoryDialog({super.key,this.data});
//
//   @override
//   State<AddCategoryDialog> createState() => _AddCategoryDialogState();
// }
//
// class _AddCategoryDialogState extends State<AddCategoryDialog> {
//   late TextEditingController nameController ;
//
//   bool type = false;
//   bool size = false;
//   bool color = false;
//   bool capacity = false;
//
//   @override
//   void initState() {
//     nameController = TextEditingController(text: widget.data!=null?widget.data!['unit']:"");
//     super.initState();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Dialog(
//       backgroundColor: Colors.white,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Container(
//         width: 400,
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             /// Title
//             const Text(
//               "Add Unit",
//               style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//             ),
//
//             const SizedBox(height: 20),
//
//             /// Category Name
//             const Text("Unit"),
//             const SizedBox(height: 6),
//             TextField(
//               controller: nameController,
//               decoration: InputDecoration(
//                 hintText: "Enter Product Unit",
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//               ),
//             ),
//
//             const SizedBox(height: 20),
//
//             /// Buttons
//             Row(
//               mainAxisAlignment: MainAxisAlignment.end,
//               children: [
//                 TextButton(
//                   onPressed: () => Navigator.pop(context),
//                   child: const Text("Cancel"),
//                 ),
//                 const SizedBox(width: 10),
//                 ElevatedButton(
//
//                   onPressed: () async {
//                     if(widget.data!=null){
//                       Navigator.pop(context);
//                       await FirebaseFirestore.instance.collection("product_units").doc(widget.data!['id']).set({
//                         "unit":nameController.text,
//                         "id":widget.data!['id']
//                       });
//
//                     }else{
//                       Navigator.pop(context);
//                       var res=await FirebaseFirestore.instance.collection("product_units").add({
//                         "unit":nameController.text
//                       });
//                       res.update({
//                         "id":res.id
//                       });
//                     }
//                   },
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.white,
//                   ),
//                   child: const Text("Save"),
//                 )
//               ],
//             )
//           ],
//         ),
//       ),
//     );
//   }
//
//   /// Checkbox widget
//   Widget checkboxItem(
//       String title, bool value, Function(bool?) onChanged) {
//     return Row(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Checkbox(value: value, onChanged: onChanged),
//         Text(title),
//       ],
//     );
//   }
// }