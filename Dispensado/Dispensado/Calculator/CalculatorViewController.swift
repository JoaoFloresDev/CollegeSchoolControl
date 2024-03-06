import UIKit
import SnapKit

protocol CalculatorViewControllerDelegate: AnyObject {
    func populateNewValue(withValue: Int)
}

class CalculatorViewController: UIViewController {
    
    weak var delegate: CalculatorViewControllerDelegate?
    var result = 0
    
    private let titleLabel1: UILabel = {
        let label = UILabel()
        label.text = "Número de aulas semanais"
        label.font = .systemFont(ofSize: 16, weight: .medium)
        return label
    }()
    
    private let textField1: UITextField = {
        let textField = UITextField()
        textField.borderStyle = .roundedRect
        textField.text = "4"
        textField.keyboardType = .phonePad
        return textField
    }()
    
    private let titleLabel2: UILabel = {
        let label = UILabel()
        label.text = "Presença minima permitida (%)"
        label.font = .systemFont(ofSize: 16, weight: .medium)
        return label
    }()
    
    private let textField2: UITextField = {
        let textField = UITextField()
        textField.borderStyle = .roundedRect
        textField.text = "75"
        textField.keyboardType = .phonePad
        return textField
    }()
    
    private let resultLabel: UILabel = {
        let label = UILabel()
        label.text = "Máximo de faltas: "
        label.font = .systemFont(ofSize: 22, weight: .medium)
        return label
    }()
    
    private let doneButton: UIButton = {
        let button = UIButton()
        button.setTitle("Inserir resultado", for: .normal)
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 28
        button.clipsToBounds = true
        button.addTarget(self, action: #selector(doneButtonTapped), for: .touchUpInside)
        return button
    }()
    
    @objc func doneButtonTapped() {
        delegate?.populateNewValue(withValue: result)
        self.dismissViewController()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupLayout()
        configureNavigationBar()
        title = "Calculadora de faltas"
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
        dismissKeyboard()
    }
    
    private func setupView() {
        view.backgroundColor = .systemGray6
        view.addSubview(titleLabel1)
        view.addSubview(textField1)
        view.addSubview(titleLabel2)
        view.addSubview(textField2)
        view.addSubview(resultLabel)
        view.addSubview(doneButton)
        textField1.delegate = self
        textField2.delegate = self
    }
    
    private func setupLayout() {
        titleLabel1.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(20)
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
        }
        
        textField1.snp.makeConstraints { make in
            make.top.equalTo(titleLabel1.snp.bottom).offset(8)
            make.leading.trailing.equalTo(titleLabel1)
            make.height.equalTo(44)
        }
        
        titleLabel2.snp.makeConstraints { make in
            make.top.equalTo(textField1.snp.bottom).offset(20)
            make.leading.trailing.equalTo(titleLabel1)
        }
        
        textField2.snp.makeConstraints { make in
            make.top.equalTo(titleLabel2.snp.bottom).offset(8)
            make.leading.trailing.equalTo(titleLabel1)
            make.height.equalTo(44)
        }
        
        resultLabel.snp.makeConstraints { make in
            make.top.equalTo(textField2.snp.bottom).offset(16)
            make.centerX.equalToSuperview()
            make.height.equalTo(44)
        }
        
        doneButton.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(24)
            make.height.equalTo(56)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(16)
        }
    }
    
    private func configureNavigationBar() {
        guard let navigationBar = navigationController?.navigationBar else { return }

        let appearance = UINavigationBarAppearance()

        appearance.backgroundColor = .systemGray5

        appearance.titleTextAttributes = [.foregroundColor: UIColor.black]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.black]

        navigationBar.standardAppearance = appearance
        navigationBar.compactAppearance = appearance
        navigationBar.scrollEdgeAppearance = appearance
        navigationBar.barStyle = .black

        let closeButton = UIBarButtonItem(title: "Fechar", style: .plain, target: self, action: #selector(dismissViewController))

        navigationItem.leftBarButtonItem = closeButton
    }

    @objc private func dismissViewController() {
        dismiss(animated: true, completion: nil)
    }

    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
        let currentResult = calcularTotalDeAulasComPrecisao(aulasSemanais: textField1.text, presencaMinima: textField2.text)
        result = currentResult
        resultLabel.text = "Máximo de faltas: \(result)"
    }
}

extension CalculatorViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return true
    }
    
    func calcularTotalDeAulasComPrecisao(
        aulasSemanais: String?,
        presencaMinima: String?
    ) -> Int {
        guard let aulasSemanais = aulasSemanais,
              let presencaMinima = presencaMinima,
              let aulasSemanaisInt = Double(aulasSemanais),
              let presencaMinimaInt = Double(presencaMinima) else {
            return 0
        }
        
        let totalDeSemanas = 4.345 * 4
        let percentMiss = (Double(100 - presencaMinimaInt) / 100)
        let result = totalDeSemanas * percentMiss * aulasSemanaisInt
        return Int(result)
    }
}
