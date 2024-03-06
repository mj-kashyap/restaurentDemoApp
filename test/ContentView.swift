//
//  ContentView.swift
//  test
//
//  Created by Manoj Kashyap on 06/03/24.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(entity: Item.entity(), sortDescriptors: [], animation: .default) private var items: FetchedResults<Item>
    
    @State private var newItemName = ""
    @State private var details = ""
    @State private var ratingsStars = ""
    @State private var selectedItem: Item?
    @State private var isShowingEmptyFieldsAlert = false
    @State private var isShowingInvalidRatingsAlert = false
    
    
    var body: some View {
        NavigationView {
            VStack {
                TextField("Enter Restaurent Name", text: $newItemName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                TextField("Enter Restaurent type", text: $details)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                // only allowing 1 to 5 ratings
                TextField("Enter ratings", text: $ratingsStars)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onReceive(ratingsStars.publisher.collect()) { str in
                        let strTxt = String(str)
                        let rating = Int(strTxt) ?? 0
                        if !(1...5).contains(rating) {
                            isShowingInvalidRatingsAlert = true
                            ratingsStars = ""
                        }
                    }
                
                Button("Save to core data") {
                    saveNewItem()
                }
                .padding()
                
                List {
                    ForEach(items) { item in
                        NavigationLink(destination: DetailView(item: item), tag: item, selection: $selectedItem) {
                            HStack {
                                HStack {
                                    Image("star")
                                        .resizable()
                                        .frame(width: 60, height: 60)
                                        .overlay(Text(item.ratings ?? "0").font(.system(size: 12)))
                                }
                                VStack {
                                    Text(item.name ?? "name")
                                    Text(item.details ?? "detail")
                                }
                                
                                HStack {
                                    Text(item.ratings ?? "0").font(.system(.caption2))
                                        .frame(maxWidth: 30, alignment: .center)
                                        .padding()
                                        .background(Color.gray.opacity(0.25))
                                        .cornerRadius(50)
                                }
                                .padding()
                            }
                        }
                        .onTapGesture {
                            selectedItem = item
                        }
                    }
                    .onDelete(perform: deleteItems)
                }
            }
            .navigationTitle("Foodie")
            .navigationBarItems(trailing: EditButton())
            .alert(isPresented: $isShowingEmptyFieldsAlert) {
                Alert(title: Text("Fields are empty"), message: Text("Please fill in all fields"), dismissButton: .default(Text("OK")))
            }
        }
    }
    
    private func saveNewItem() {
        guard !newItemName.isEmpty, !details.isEmpty, !ratingsStars.isEmpty else {
            // Show an alert or perform some other action to indicate that the fields are empty
            isShowingEmptyFieldsAlert = true
            return
        }
        withAnimation {
            let newItem = Item(context: viewContext)
            newItem.name = newItemName
            newItem.details = details
            newItem.ratings = ratingsStars
            saveContext()
            clearData()
        }
        func clearData() {
            newItemName = ""
            details = ""
            ratingsStars = ""
        }
    }
    
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { items[$0] }.forEach(viewContext.delete)
            saveContext()
        }
    }
    
    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
}


struct DetailView: View {
    let item: Item
    var body: some View {
        VStack {
            Text(item.name ?? "Name")
            Text(item.details ?? "Details")
            Text(item.ratings ?? "0")
        }
        .navigationTitle("Detail")
    }
}


private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
