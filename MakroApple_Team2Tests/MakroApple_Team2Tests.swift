//
//  MakroApple_Team2Tests.swift
//  MakroApple_Team2Tests
//
//  Created by Alfred Hans Witono on 31/10/25.

//
import Testing
import Foundation
@testable import MakroApple_Team2

struct MakroApple_Team2Tests {
    
    @Suite("✅ EditOrderViewModel - JSON Parsing Success")
    struct EditOrderViewModelPositiveTests {
        
        @Test("Parses customer fields correctly")
        @MainActor
        func parseCustomerFields() {
            let viewModel = EditOrderViewModel()
            let data: [String: Any] = [
                "Nama Pemesan": "Nadia Prameswari",
                "No. Telp Pemesan": "0812-5566-2233",
                "Nama Penerima": "Rafi Setiawan",
                "No. Telp Penerima": "0813-7788-9922",
                "Alamat Kirim": "Jl. Dharmahusada"
            ]
            
            viewModel.configure(parsedOrderData: data)
            
            #expect(viewModel.customerFields.count == 5)
            #expect(viewModel.customerFields[0].value == "Nadia Prameswari")
        }
        
        @Test("Parses single product correctly")
        @MainActor
        func parseSingleProduct() {
            let viewModel = EditOrderViewModel()
            let data: [String: Any] = [
                "Pesanan": [
                    "[[{\"item\": \"Strawberry Fresh Cream Cake – ukuran 18 cm\", \"quantity\": 1}]]"
                ]
            ]
            
            viewModel.configure(parsedOrderData: data)
            
            #expect(viewModel.products.count == 1)
            #expect(viewModel.products[0].name == "Strawberry Fresh Cream Cake – ukuran 18 cm")
        }
        
        @Test("Parses multiple add-ons")
        @MainActor
        func parseMultipleAddOns() {
            let viewModel = EditOrderViewModel()
            let data: [String: Any] = [
                "Adds-on": [
                    "[[{\"item\": \"Lilin angka \\u201c30\\u201d\", \"quantity\": 1}, {\"item\": \"pita dekorasi merah\", \"quantity\": 1}]]"
                ]
            ]
            
            viewModel.configure(parsedOrderData: data)
            
            #expect(viewModel.addOns.count == 2)
        }
    }
    
    @Suite("❌ EditOrderViewModel - Error Handling")
    struct EditOrderViewModelNegativeTests {
        
        @Test("Handles empty order gracefully")
        @MainActor
        func handleEmptyOrder() {
            let viewModel = EditOrderViewModel()
            let data: [String: Any] = [:]
            
            viewModel.configure(parsedOrderData: data)
            
            #expect(viewModel.products.count >= 1)
            #expect(viewModel.addOns.count >= 1)
        }
        
        @Test("Handles invalid JSON in products")
        @MainActor
        func handleInvalidProductJSON() {
            let viewModel = EditOrderViewModel()
            let data: [String: Any] = [
                "Pesanan": ["invalid json {{{"]
            ]
            
            viewModel.configure(parsedOrderData: data)
            
            #expect(viewModel.products.count >= 1)
        }
        
        @Test("Handles null values gracefully")
        @MainActor
        func handleNullValues() {
            let viewModel = EditOrderViewModel()
            let data: [String: Any] = [
                "Nama Pemesan": NSNull(),
                "Pesanan": NSNull()
            ]
            
            viewModel.configure(parsedOrderData: data)
            
            #expect(viewModel.products.count >= 1)
        }
    }
    
    @Suite("🔍 Product Management")
    struct ProductManagementTests {
        
        @Test("Can add a product")
        @MainActor
        func addProduct() {
            let viewModel = EditOrderViewModel()
            viewModel.products = []
            
            viewModel.addProduct()
            
            #expect(viewModel.products.count == 1)
        }
        
        @Test("Can delete product when multiple exist")
        @MainActor
        func deleteProductWhenMultiple() {
            let viewModel = EditOrderViewModel()
            viewModel.products = [
                ProductItem(category: "Cake", name: "Cake 1", quantity: 1),
                ProductItem(category: "Cake", name: "Cake 2", quantity: 1)
            ]
            
            viewModel.deleteProduct(at: 0)
            
            #expect(viewModel.products.count == 1)
            #expect(viewModel.products[0].name == "Cake 2")
        }
        
        @Test("Cannot delete last product")
        @MainActor
        func cannotDeleteLastProduct() {
            let viewModel = EditOrderViewModel()
            viewModel.products = [
                ProductItem(category: "Cake", name: "Last", quantity: 1)
            ]
            
            viewModel.deleteProduct(at: 0)
            
            #expect(viewModel.products.count == 1)
        }
    }
    
    @Suite("➕ Add-On Management")
    struct AddOnManagementTests {
        
        @Test("Can add an add-on")
        @MainActor
        func addAddOn() {
            let viewModel = EditOrderViewModel()
            viewModel.addOns = []
            
            viewModel.addAddOn()
            
            #expect(viewModel.addOns.count == 1)
        }
        
        @Test("Can delete add-on when multiple exist")
        @MainActor
        func deleteAddOnWhenMultiple() {
            let viewModel = EditOrderViewModel()
            viewModel.addOns = [
                AddOnItem(name: "Candles", quantity: 1),
                AddOnItem(name: "Ribbon", quantity: 1)
            ]
            
            viewModel.deleteAddOn(at: 0)
            
            #expect(viewModel.addOns.count == 1)
        }
    }
    
    @Suite("📊 Data Structures")
    struct DataStructureTests {
        
        @Test("ProductItem maintains structure")
        func productStructure() {
            let product = ProductItem(
                category: "Cake",
                name: "Strawberry",
                quantity: 2
            )
            
            #expect(product.category == "Cake")
            #expect(product.name == "Strawberry")
            #expect(product.quantity == 2)
        }
        
        @Test("AddOnItem maintains structure")
        func addOnStructure() {
            let addOn = AddOnItem(name: "Candles", quantity: 1)
            
            #expect(addOn.name == "Candles")
            #expect(addOn.quantity == 1)
        }
    }
}

