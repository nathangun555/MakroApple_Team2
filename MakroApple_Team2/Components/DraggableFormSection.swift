////
////  DraggableFormSection.swift
////  MakroApple_Team2
////
////  Created by Alfred Hans Witono on 16/11/25.
////
//


//import SwiftUI
//import UniformTypeIdentifiers
//
//struct DraggableFormSection: View {
//    let title: String
//    @Binding var fields: [FormFieldItem]
//    let onAddColumn: () -> Void
//    var showDelete: Bool = false
//    var onDelete: ((Int) -> Void)? = nil
//    var isEditable: Bool = true
//    var focusedIndex: FocusState<Int?>.Binding
//    var onReorder: (([FormFieldItem]) -> Void)? = nil
//
//    @State private var draggingItem: FormFieldItem?
//
//    var body: some View {
//        VStack(alignment: .leading, spacing: 12) {
//
//            // Header
//            HStack {
//                Text(title)
//                    .font(.title3)
//                    .fontWeight(.bold)
//
//                Spacer()
//
//                Button(action: onAddColumn) {
//                    Label("Tambahkan Kolom", systemImage: "plus")
//                        .font(.subheadline)
//                        .foregroundColor(.primaryButton)
//                }
//                .buttonStyle(.bordered)
//                .tint(.gray)
//            }
//            .padding(.horizontal)
//
//            // Draggable Items
//            VStack(spacing: 0) {
//                ForEach(Array(fields.enumerated()), id: \.element.id) { index, field in
//                    if field.label != "Foto Referensi (optional)" {
//
//                        HStack(spacing: 12) {
//                            
//                            Image(systemName: "line.3.horizontal")
//                                .font(.system(size: 16))
//                                .foregroundColor(.gray)
//                                .padding(.trailing, 4)
//                               
//                                
//
//                            TextField(
//                                "",
//                                text: Binding(
//                                    get: { field.label },
//                                    set: { newValue in
//                                        if let i = fields.firstIndex(where: { $0.id == field.id }) {
//                                            fields[i].label = newValue
//                                        }
//                                    }
//                                )
//                            )
//                            .focused(focusedIndex, equals: index)
//                            .disabled(!isEditable)
//                            .frame(maxWidth: .infinity, alignment: .leading)
//                            .font(.body)
//                            .multilineTextAlignment(.leading)
//                            .textFieldStyle(RoundedBorderTextFieldStyle())
//
//                            Text("")
//                                .frame(maxWidth: .infinity, alignment: .leading)
//                                .padding(.horizontal, 12)
//                                .padding(.vertical, 8)
//                                .background(Color(.systemGray6))
//                                .cornerRadius(8)
//                                .overlay(
//                                    RoundedRectangle(cornerRadius: 8)
//                                        .stroke(Color(.systemGray4), lineWidth: 1)
//                                )
//                                .foregroundColor(.secondary)
//
//                            if showDelete, let onDelete = onDelete {
//                                Button(action: { onDelete(index) }) {
//                                    Image(systemName: "trash.fill")
//                                        .foregroundColor(.red)
//                                }
//                            }
//                        }
//                        .onDrag {
//                            draggingItem = field
//                            return NSItemProvider(item: field.id.uuidString as NSString, typeIdentifier: UTType.text.identifier)
//                        }
//                        .padding(.horizontal)
//                        .background(
//                            (draggingItem?.id == field.id) ? Color(.systemGray5) : Color.clear
//                        )
//                        .onDrop(
//                            of: [UTType.text],
//                            delegate: DropViewDelegate(
//                                item: field,
//                                fields: $fields,
//                                draggingItem: $draggingItem,
//                                onReorder: onReorder
//                            )
//                        )
//                        .background(
//                            (draggingItem?.id == field.id)
//                            ? Color.gray.opacity(0.3)
//                            : Color.clear
//                        )
//                        .animation(.easeInOut, value: draggingItem)
//                    }
//                }
//            }
//            .animation(.easeInOut, value: fields)
//        }
//    }
//}
//
//
//struct DropViewDelegate: DropDelegate {
//    let item: FormFieldItem
//    @Binding var fields: [FormFieldItem]
//    @Binding var draggingItem: FormFieldItem?
//    var onReorder: (([FormFieldItem]) -> Void)?
//
//    func dropEntered(info: DropInfo) {
//        print("DROP ENTERED")
//        guard
//            let dragging = draggingItem,
//            let from = fields.firstIndex(where: { $0.id == dragging.id }),
//            let to = fields.firstIndex(where: { $0.id == item.id }),
//            from != to
//        else { return }
//
//        withAnimation {
//            fields.move(
//                fromOffsets: IndexSet(integer: from),
//                toOffset: to > from ? to + 1 : to
//            )
//        }
//    }
//
//    func performDrop(info: DropInfo) -> Bool {
//        onReorder?(fields)
//        draggingItem = nil
//        return true
//    }
//}
//
////extension FormFieldItem: Transferable {
////    static var transferRepresentation: some TransferRepresentation {
////        ProxyRepresentation(exporting: { item in
////            item.id.uuidString
////        }, importing: { idString in
////            FormFieldItem(label: "",
////                          value: "")
////        })
////    }
////}
