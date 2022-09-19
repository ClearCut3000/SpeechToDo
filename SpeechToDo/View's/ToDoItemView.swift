//
//  ToDoView.swift
//  SpeechToDo
//
//  Created by Николай Никитин on 19.09.2022.
//

import SwiftUI

struct ToDoItemView: View {

  //MARK: - View Properties
  var index: Int = 0
  var text: String = ""
  var date: String = "00/00/00"

  //MARK: - View Body
  var body: some View {
    HStack {
      Image(systemName: "\(index).circle.fill")
        .resizable()
        .frame(width: 40, height: 40)
        .padding(.trailing, 10)
        .foregroundColor(.red)
      VStack {
        Text(text)
          .font(.headline)
        Text(date)
          .font(.caption2)
      }
    }
  }
}

struct ToDoView_Previews: PreviewProvider {
  static var previews: some View {
    ToDoItemView()
  }
}
