//
//  VisualBarView.swift
//  SpeechToDo
//
//  Created by Николай Никитин on 16.09.2022.
//

import SwiftUI

struct VisualBarView: View {

  //MARK: - View Properties
  var value: CGFloat
  let numberOfSamples: Int = 30

  //MARK: View Body
    var body: some View {
      ZStack {
        RoundedRectangle(cornerRadius: 20)
          .fill(LinearGradient(gradient: Gradient(colors: [.green, .blue]),
                               startPoint: .top,
                               endPoint: .bottom))
          .frame(width: UIScreen.main.bounds.width - CGFloat(numberOfSamples) * 10 / CGFloat(numberOfSamples),
                 height: value)
      }
    }
}

struct VisualBarView_Previews: PreviewProvider {
    static var previews: some View {
        VisualBarView(value: 10)
    }
}
