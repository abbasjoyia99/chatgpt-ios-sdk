//
//  TextViewController.swift
//  Example
//
//  Created by Ghullam Abbas on 19/06/2023.
//

import UIKit
import ChatGPTAPIManager
class TextViewController: UIViewController {
    
    // MARK: - IBOutlets
    @IBOutlet weak var textFieldBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var messageTextField: UITextField!
    @IBOutlet private weak var tableView: UITableView!
    private var chatMessages: [ChatMessage] = []
    var currentSolution = ""
    
    // MARK: - Variables
    
    let chatGPTAPI = ChatGPTAPIManager(apiKey: "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")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
       
        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableFooterView = UIView()
        
        messageTextField.delegate = self
        tableView.register(UINib(nibName: "UserCell", bundle: nil), forCellReuseIdentifier: "UserCell")
        tableView.register(UINib(nibName: "AssistantCell", bundle: nil), forCellReuseIdentifier: "AssistantCell")
        
        // Register for keyboard notifications
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        // Add a tap gesture recognizer to dismiss the keyboard
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)

    }
    // MARK: - Keyboard
    @objc func keyboardWillShow(_ notification: Notification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            let keyboardHeight = keyboardSize.height
            let safeAreaBottomInset = view.safeAreaInsets.bottom
            
            textFieldBottomConstraint.constant = keyboardHeight - safeAreaBottomInset
            
            UIView.animate(withDuration: 0.3) {
                self.view.layoutIfNeeded()
            }
        }
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {
        textFieldBottomConstraint.constant = 0
        
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    deinit {
        // Unregister for keyboard notifications
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - IBAction
    @IBAction func sendMessage(_ sender: UIButton) {
        if let message = messageTextField.text, !message.isEmpty {
            // Send user message to ChatGPT
            self.messageTextField.resignFirstResponder()
            self.sendTextCompletionChatGPT(message)
        }
    }
    // MARK: - NetworkCall
    
    func sendTextCompletionChatGPT(_ message: String) {
        
        let userMessage = ChatMessage(content: message, role: Role.user.rawValue)
        chatMessages.append(userMessage)
        tableView.reloadData()
        
        messageTextField.text = ""
        
        EZLoadingActivity.show("Loading...", disableUI: true)
        chatGPTAPI.sendTextRequest(prompt: self.currentSolution + message,model: .textDavinci003,endPoint: .completion) { result in
            switch result {
            case .success(let response):
                print("API response: \(response)")
                // Handle the response as needed
                
                DispatchQueue.main.async {
                    self.currentSolution = response
                    let assistantMessage = ChatMessage(content: response, role: Role.assistant.rawValue)
                    self.chatMessages.append(assistantMessage)
                    self.tableView.reloadData()
                    
                    // Scroll to the last message
                    let lastRow = (self.chatMessages.count) - 1
                    let indexPath = IndexPath(row: lastRow, section: 0)
                    self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
                    EZLoadingActivity.hide(true,animated: true)
                }
                
            case .failure(let error):
                print("API error: \(error.localizedDescription)")
                // Handle the error gracefully
                DispatchQueue.main.async {
                    EZLoadingActivity.hide(false,animated: true)
                }
            }
        }
        
    }
}

extension TextViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return chatMessages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let message = chatMessages[indexPath.row]
        
        let cellIdentifier = message.role == "user" ? "UserCell" : "AssistantCell"
        
        if (message.role == "user") {
            let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! UserCell
            cell.configure(with: message)
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! AssistantCell
            cell.configure(with: message)
            return cell
        }
        
        
        
    }
}

extension TextViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let message = chatMessages[indexPath.row]
        let labelWidth = tableView.frame.width - 40 // Adjust as needed
        let labelFont = UIFont.systemFont(ofSize: 17) // Adjust font size if necessary
        let labelHeight = message.content.height(withConstrainedWidth: labelWidth, font: labelFont)
        return labelHeight + 20 // Add padding
    }
}

extension TextViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if string == "\n" {
            sendTextCompletionChatGPT(textField.text ?? "")
            return false
        }
        return true
    }
}
