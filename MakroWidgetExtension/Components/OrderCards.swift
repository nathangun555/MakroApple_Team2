//
//  OrderCards.swift
//  MakroApple_Team2
//
//  Created by Edward Suwandi on 29/12/25.
//

import SwiftUI

@ViewBuilder
func mediumWidgetOrderCard(time: String, title: String, color: Color) -> some View {
    HStack(spacing: 4) {
        RoundedRectangle(cornerRadius: 3)
            .frame(width: 6)
            .foregroundColor(color)
        
        VStack(alignment: .leading, spacing: 2) {
            Text(time)
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Text(title)
                .font(.caption.bold())
                .lineLimit(1)
        }
        
        Spacer()
    }
    .padding(.vertical, 4)
    .padding(.horizontal, 4)
    .frame(maxWidth: .infinity, maxHeight: 50)
    .background(
        LinearGradient(colors: [Color.white.opacity(0.15), color.opacity(0.20)],
                       startPoint: .leading,
                       endPoint: .trailing)
    )
    .clipShape(RoundedRectangle(cornerRadius: 10))
}


@ViewBuilder
func largeWidgetOrderCard(name: String, title: String, time: String, color: Color, extraCount: Int) -> some View {
    HStack(spacing: 10) {

        RoundedRectangle(cornerRadius: 3)
            .frame(width: 6)
            .foregroundColor(color)

        VStack(alignment: .leading, spacing: 6) {
            
            HStack{
                
                Text(name)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                Spacer()
                Text(time)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }

            Text(title)
                .font(.system(size: 15, weight: .semibold))
            
            if extraCount > 0 {
                Text("+\(extraCount) more")
                    .font(Font.caption2.bold())
                    .foregroundColor(.secondary)
            }
            
        }
        .padding(.vertical,10)

        Spacer()

       
    }
    .frame(maxHeight: 70)
    .padding(.horizontal, 6)
    
    .background(
        LinearGradient(
            colors: [Color.white.opacity(0.15), color.opacity(0.15)],
            startPoint: .leading,
            endPoint: .trailing
        )
    )
    .clipShape(RoundedRectangle(cornerRadius: 16))
}
