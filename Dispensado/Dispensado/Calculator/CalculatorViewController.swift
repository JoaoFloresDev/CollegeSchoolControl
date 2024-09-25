import UIKit
import SnapKit

protocol CalculatorViewControllerDelegate: AnyObject {
    func populateNewValue(withValue: Int)
}

class CalculatorViewController: UIViewController {

    weak var delegate: CalculatorViewControllerDelegate?
    var result = 0

    private var selectedWeekdays: [Int] = []
    private var selectedStartDate: Date?
    private var selectedEndDate: Date?

    private let dayNameToWeekdayNumber: [String: Int] = [
        "Domingo": 1,
        "Segunda-feira": 2,
        "Terça-feira": 3,
        "Quarta-feira": 4,
        "Quinta-feira": 5,
        "Sexta-feira": 6,
        "Sábado": 7
    ]

    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        return scrollView
    }()

    private let contentView: UIView = {
        let view = UIView()
        return view
    }()

    private let titleLabel2: UILabel = {
        let label = UILabel()
        label.text = "Presença \nmínima (%)"
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 16, weight: .medium)
        return label
    }()

    private let textField2: UITextField = {
        let textField = UITextField()
        textField.borderStyle = .roundedRect
        textField.text = "75"
        textField.keyboardType = .decimalPad
        return textField
    }()

    private let startDateTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Data inicial"
        label.font = .systemFont(ofSize: 16, weight: .medium)
        return label
    }()

    private let startDateTextField: UITextField = {
        let textField = UITextField()
        textField.borderStyle = .roundedRect
        textField.placeholder = "Selecione a data inicial"
        return textField
    }()

    private let endDateTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Data final"
        label.font = .systemFont(ofSize: 16, weight: .medium)
        return label
    }()

    private let endDateTextField: UITextField = {
        let textField = UITextField()
        textField.borderStyle = .roundedRect
        textField.placeholder = "Selecione a data final"
        return textField
    }()

    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 10
        stack.alignment = .fill
        stack.distribution = .fill
        return stack
    }()

    private let addButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Adicionar dias de aula", for: .normal)
        button.backgroundColor = .systemGreen
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        button.addTarget(self, action: #selector(addColorView), for: .touchUpInside)
        return button
    }()

    private let resultLabel: UILabel = {
        let label = UILabel()
        label.text = "Adicione os valores para calcularmos o maximo de faltas"
        label.font = .systemFont(ofSize: 18, weight: .medium)
        label.textAlignment = .center
        label.numberOfLines = 0
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

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupLayout()
        configureNavigationBar()
        title = "Calculadora de faltas"
    }

    private func setupView() {
        view.backgroundColor = .systemGray6
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        contentView.addSubview(titleLabel2)
        contentView.addSubview(textField2)
        contentView.addSubview(startDateTitleLabel)
        contentView.addSubview(startDateTextField)
        contentView.addSubview(endDateTitleLabel)
        contentView.addSubview(endDateTextField)
        contentView.addSubview(stackView)
        contentView.addSubview(addButton)
        contentView.addSubview(doneButton)
        contentView.addSubview(resultLabel)

        textField2.delegate = self
        startDateTextField.delegate = self
        endDateTextField.delegate = self

        textField2.addTarget(self, action: #selector(textField2EditingChanged), for: .editingChanged)
    }

    private func setupLayout() {
        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }

        contentView.snp.makeConstraints { make in
            make.edges.equalTo(scrollView)
            make.width.equalTo(scrollView)
        }

        titleLabel2.snp.makeConstraints { make in
            make.top.equalTo(contentView).offset(20)
            make.leading.equalToSuperview().offset(20)
            make.width.equalTo(100)
        }

        textField2.snp.makeConstraints { make in
            make.centerY.equalTo(titleLabel2)
            make.leading.equalTo(titleLabel2.snp.trailing).offset(8)
            make.trailing.equalToSuperview().offset(-20)
            make.height.equalTo(44)
        }

        startDateTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel2.snp.bottom).offset(20)
            make.leading.equalToSuperview().offset(20)
            make.width.equalTo(100)
        }

        startDateTextField.snp.makeConstraints { make in
            make.centerY.equalTo(startDateTitleLabel)
            make.leading.equalTo(startDateTitleLabel.snp.trailing).offset(8)
            make.trailing.equalToSuperview().offset(-20)
            make.height.equalTo(44)
        }

        endDateTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(startDateTitleLabel.snp.bottom).offset(30)
            make.leading.equalToSuperview().offset(20)
            make.width.equalTo(100)
        }

        endDateTextField.snp.makeConstraints { make in
            make.centerY.equalTo(endDateTitleLabel)
            make.leading.equalTo(endDateTitleLabel.snp.trailing).offset(8)
            make.trailing.equalToSuperview().offset(-20)
            make.height.equalTo(44)
        }

        stackView.snp.makeConstraints { make in
            make.top.equalTo(endDateTextField.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview().inset(20)
        }

        addButton.snp.makeConstraints { make in
            make.top.equalTo(stackView.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(50)
        }

        resultLabel.snp.makeConstraints { make in
            make.top.equalTo(addButton.snp.bottom).offset(26)
            make.leading.trailing.equalToSuperview().inset(20)
        }

        doneButton.snp.makeConstraints { make in
            make.top.equalTo(resultLabel.snp.bottom).offset(26)
            make.leading.trailing.equalToSuperview().inset(24)
            make.height.equalTo(56)
            make.bottom.equalToSuperview().offset(-20)
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

    @objc private func addColorView() {
        let alert = UIAlertController(title: "Selecione um dia da semana", message: nil, preferredStyle: .actionSheet)

        let diasDaSemana = ["Domingo", "Segunda-feira", "Terça-feira", "Quarta-feira", "Quinta-feira", "Sexta-feira", "Sábado"]

        for dia in diasDaSemana {
            alert.addAction(UIAlertAction(title: dia, style: .default, handler: { [weak self] _ in
                self?.adicionarDiaNaStackView(dia: dia)
            }))
        }

        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel, handler: nil))

        if let popoverController = alert.popoverPresentationController {
            popoverController.sourceView = self.addButton
            popoverController.sourceRect = self.addButton.bounds
        }

        present(alert, animated: true, completion: nil)
    }

    private func adicionarDiaNaStackView(dia: String) {
        guard let weekdayNumber = dayNameToWeekdayNumber[dia] else { return }
        selectedWeekdays.append(weekdayNumber)

        let diaView = UIView()
        diaView.backgroundColor = .systemGray5
        diaView.layer.cornerRadius = 8
        diaView.tag = weekdayNumber

        let label = UILabel()
        label.text = dia
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textAlignment = .left

        let deleteButton = UIButton(type: .system)
        deleteButton.setTitle("Delete", for: .normal)
        deleteButton.setTitleColor(.red, for: .normal)
        deleteButton.addTarget(self, action: #selector(deleteDayView(_:)), for: .touchUpInside)
        deleteButton.tag = weekdayNumber

        let horizontalStack = UIStackView(arrangedSubviews: [label, deleteButton])
        horizontalStack.axis = .horizontal
        horizontalStack.spacing = 8
        horizontalStack.alignment = .center
        horizontalStack.distribution = .fill

        diaView.addSubview(horizontalStack)
        horizontalStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(10)
        }

        diaView.snp.makeConstraints { make in
            make.height.equalTo(50)
        }

        stackView.addArrangedSubview(diaView)

        updateResult()
    }

    @objc private func deleteDayView(_ sender: UIButton) {
        let weekdayNumber = sender.tag
        if let index = selectedWeekdays.firstIndex(of: weekdayNumber) {
            selectedWeekdays.remove(at: index)
        }
        if let horizontalStack = sender.superview as? UIStackView,
           let diaView = horizontalStack.superview {
            stackView.removeArrangedSubview(diaView)
            diaView.removeFromSuperview()
        }

        updateResult()
    }

    @objc private func textField2EditingChanged() {
        updateResult()
    }

    @objc func doneButtonTapped() {
        let missingFields = getMissingFields()
        if !missingFields.isEmpty {
            let fields = missingFields.joined(separator: ", ")
            let alert = UIAlertController(title: "Informações Faltando", message: "Adicione as informações: \(fields).", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
        } else {
            delegate?.populateNewValue(withValue: result)
            self.dismissViewController()
        }
    }

    @objc private func dismissViewController() {
        dismiss(animated: true, completion: nil)
    }

    private func getMissingFields() -> [String] {
        var missingFields = [String]()

        if selectedStartDate == nil {
            missingFields.append("Data inicial")
        }

        if selectedEndDate == nil {
            missingFields.append("Data final")
        }

        if let startDate = selectedStartDate, let endDate = selectedEndDate {
            if startDate > endDate {
                missingFields.append("A data inicial deve ser anterior à data final")
            }
        }

        if selectedWeekdays.isEmpty {
            missingFields.append("Dias da semana")
        }

        if textField2.text == nil || textField2.text!.isEmpty || Double(textField2.text!) == nil {
            missingFields.append("Presença mínima permitida (%)")
        }

        return missingFields
    }

    private func updateResult() {
        let currentResult = calcularTotalDeAulasComPrecisao(presencaMinima: textField2.text)
        result = currentResult

        if result == 0 {
            let missingFields = getMissingFields()
            if !missingFields.isEmpty {
                let fields = missingFields.joined(separator: ", ")
                resultLabel.text = "Adicione as informações: \(fields)."
            } else {
                resultLabel.text = "Máximo de faltas: \(result)"
            }
        } else {
            resultLabel.text = "Máximo de faltas: \(result)"
        }
    }

    func calcularTotalDeAulasComPrecisao(presencaMinima: String?) -> Int {
        guard let presencaMinima = presencaMinima,
              let presencaMinimaDouble = Double(presencaMinima),
              let startDate = selectedStartDate,
              let endDate = selectedEndDate,
              startDate <= endDate,
              !selectedWeekdays.isEmpty else {
            return 0
        }

        var totalClasses = 0
        var currentDate = startDate
        let calendar = Calendar.current

        while currentDate <= endDate {
            let weekday = calendar.component(.weekday, from: currentDate)
            if selectedWeekdays.contains(weekday) {
                totalClasses += 1
            }
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }

        let absencePercentage = (100 - presencaMinimaDouble) / 100
        let maxAbsences = Int(Double(totalClasses) * absencePercentage)

        return maxAbsences
    }
}

extension CalculatorViewController: UITextFieldDelegate {

    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if textField == startDateTextField {
            showDatePicker(for: textField, title: "Data inicial") { [weak self] selectedDate in
                self?.selectedStartDate = selectedDate
                self?.updateResult()
            }
            return false
        } else if textField == endDateTextField {
            showDatePicker(for: textField, title: "Data final") { [weak self] selectedDate in
                self?.selectedEndDate = selectedDate
                self?.updateResult()
            }
            return false
        }
        return true
    }

    private func showDatePicker(for textField: UITextField, title: String, dateSetter: @escaping (Date) -> Void) {
        let datePickerVC = DatePickerViewController()
        datePickerVC.titleText = title
        datePickerVC.onDateSelected = { [weak self] selectedDate in
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.locale = Locale.current
            let dateString = formatter.string(from: selectedDate)
            textField.text = dateString
            dateSetter(selectedDate)
            self?.updateResult()
        }

        if let sheet = datePickerVC.sheetPresentationController {
            sheet.detents = [.medium()]
            sheet.prefersGrabberVisible = true
        }

        datePickerVC.modalPresentationStyle = .pageSheet
        present(datePickerVC, animated: true, completion: nil)
    }
}


//extension CalculatorViewController: UITextFieldDelegate {
//
//    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
//        if textField == startDateTextField {
//            showDatePicker(for: textField, title: "Data inicial") { [weak self] selectedDate in
//                self?.selectedStartDate = selectedDate
//            }
//            return false
//        } else if textField == endDateTextField {
//            showDatePicker(for: textField, title: "Data final") { [weak self] selectedDate in
//                self?.selectedEndDate = selectedDate
//            }
//            return false
//        }
//        return true
//    }
//}


class DatePickerViewController: UIViewController {
    
    var onDateSelected: ((Date) -> Void)?
    var titleText: String?
    
    private let datePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.datePickerMode = .date
        picker.preferredDatePickerStyle = .wheels
        return picker
    }()
    
    private let selectButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Selecionar", for: .normal)
        button.addTarget(self, action: #selector(selectDate), for: .touchUpInside)
        return button
    }()
    
    private let cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Cancelar", for: .normal)
        button.addTarget(self, action: #selector(cancelDateSelection), for: .touchUpInside)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = titleText
        setupLayout()
    }
    
    private func setupLayout() {
        view.backgroundColor = .white
        view.addSubview(datePicker)
        view.addSubview(selectButton)
        
        datePicker.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        selectButton.snp.makeConstraints { make in
            make.top.equalTo(datePicker.snp.bottom).offset(20)
            make.centerX.equalToSuperview()
            make.width.equalTo(100)
        }
    }
    
    @objc private func selectDate() {
        onDateSelected?(datePicker.date)
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func cancelDateSelection() {
        dismiss(animated: true, completion: nil)
    }
}

extension CalculatorViewController {
    
//    @objc private func startDateButtonTapped() {
//        showDatePicker(for: startDateLabel, title: "Data inicial")
//    }
//
//    @objc private func endDateButtonTapped() {
//        showDatePicker(for: endDateLabel, title: "Data final")
//    }

    private func showDatePicker(for label: UILabel, title: String) {
        let datePickerVC = DatePickerViewController()
        datePickerVC.onDateSelected = { [weak self] selectedDate in
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.locale = Locale.current  // Define a localidade para o idioma do device
            let dateString = formatter.string(from: selectedDate)
            label.textAlignment = .left
            label.text = "\(title): \(dateString)"
        }

        if let sheet = datePickerVC.sheetPresentationController {
            sheet.detents = [.medium()]
            sheet.prefersGrabberVisible = true
        }

        datePickerVC.modalPresentationStyle = .pageSheet
        present(datePickerVC, animated: true, completion: nil)
    }

}

extension UIColor {
    static func randomColor() -> UIColor {
        return UIColor(
            red: .random(in: 0...1),
            green: .random(in: 0...1),
            blue: .random(in: 0...1),
            alpha: 1.0
        )
    }
}
