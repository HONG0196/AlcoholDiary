//
//  DetailViewController.swift
//  Alcohol Diary
//
//  Created by 양홍찬 on 2023/07/13.
//

import UIKit

class DetailViewController: UIViewController, UIGestureRecognizerDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var distilleryField: UITextField!
    @IBOutlet weak var ABVField: UITextField!
    @IBOutlet weak var agedField: UITextField!
    @IBOutlet weak var caskField: UITextField!
    
    @IBOutlet weak var noseTextView: UITextView!
    @IBOutlet weak var palateTextView: UITextView!
    @IBOutlet weak var finishTextView: UITextView!
    
    @IBOutlet weak var ratingLabel: UILabel!
    @IBOutlet weak var ratingSlider: UISlider!
    
    @IBOutlet weak var button: UIButton!
    
    // 모델(저장 데이터를 관리하는 코어데이터)
    let alcoholManager = CoreDataManager.shared
    
    // 선택된 셀의 인덱스 경로를 저장할 프로퍼티
    var selectedIndexPath: IndexPath?
    
    // 수정할 데이터를 저장할 프로퍼티
    var alData: AlcoholData?
    
    // 수정 완료 후 호출될 클로저
    var updateCompletion: (() -> Void)?
    
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        touchGesture()
        setupTapGestures()
        setUpTextView()
        setUpTextField()
        
    }
    

    // MARK: - UI Setup
    
    func setupUI() {
            ratingSlider.addTarget(self, action: #selector(sliderValueChanged), for: .valueChanged)
            
            if let alData = self.alData {
                self.title = "Update"
                if let imageData = alData.image, let image = UIImage(data: imageData) {
                    imageView.image = image
                }
                
                nameField.text = alData.name
                distilleryField.text = alData.distillery
                ABVField.text = alData.abv
                agedField.text = alData.aged
                caskField.text = alData.cask
                noseTextView.text = alData.nose
                palateTextView.text = alData.palate
                finishTextView.text = alData.finish
                
                if let rating = alData.ratingScore {
                    // 평점을 슬라이더에 반영
                    ratingSlider.value = Float(rating)!
                    sliderValueChanged()
                }
                button.setTitle("Update", for: .normal)
                deleteButton()
            } else {
                // 새로운 데이터 추가 모드일 때
                self.title = "New"
                button.setTitle("Save", for: .normal)
            }
    }
    
    // 네비게이션 바 삭제 버튼 생성
    func deleteButton() {
        let deleteButton = UIBarButtonItem(title: "Delete", style: .plain, target: self, action: #selector(deleteButtonTapped))
        deleteButton.tintColor = .red
        navigationItem.rightBarButtonItem = deleteButton
    }
    
    // 삭제 버튼 클릭 시 호출되는 메서드
    @objc func deleteButtonTapped() {
        if let alData = self.alData {
            // 선택한 셀의 데이터를 삭제
            alcoholManager.deleteAlcohol(data: alData) { [weak self] result in
                switch result {
                case .success:
                    print("삭제 완료")
                    self?.navigationController?.popViewController(animated: true)
                case .failure(let error):
                    print("삭제 실패: \(error.localizedDescription)")
                }
            }
        }
    }
    
    @IBAction func saveButtonTapped(_ sender: UIButton) {
        if let alData = self.alData {
            guard let image = imageView.image,
                  let imageData = image.fixOrientation().jpegData(compressionQuality: 0.8) else {
                // 이미지가 없거나 이미지 데이터를 가져오는 데 실패한 경우
                return
            }
            
            alData.image = imageData
            alData.name = nameField.text
            alData.distillery = distilleryField.text
            alData.abv = ABVField.text
            alData.aged = agedField.text
            alData.cask = caskField.text
            alData.nose = noseTextView.text
            alData.palate = palateTextView.text
            alData.finish = finishTextView.text
            alData.ratingScore = ratingLabel.text
            
            
            alcoholManager.updateAlcohol(newAlcoholData: alData) { result in
                switch result {
                case .success:
                    print("업데이트 완료")
                    self.navigationController?.popViewController(animated: true)
                case .failure(let error):
                    print("업데이트 실패: \(error.localizedDescription)")
                }
            }
            // 기존 데이터가 없을 때 ===> 새로운 데이터 생성
        } else {
            guard let image = imageView.image,
                  let imageData = image.fixOrientation().jpegData(compressionQuality: 0.8) else {
                // 이미지가 없거나 이미지 데이터를 가져오는 데 실패한 경우
                return
            }
            
            alcoholManager.saveAlcoholData(alImage: imageData, nameText: nameField.text, distilleryText: distilleryField.text, abvText: ABVField.text, agedText: agedField.text, caskText: caskField.text, noseText: noseTextView.text, palateText: palateTextView.text, finishText: finishTextView.text, rating: ratingLabel.text) { result in
                switch result {
                case .success:
                    print("저장 완료")
                    self.navigationController?.popViewController(animated: true)
                case .failure(let error):
                    print("저장 실패: \(error.localizedDescription)")
                }
            }
        }
    }
    
    
    
    // 이미지뷰에 터치 제스처 설정
    func setupTapGestures() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(touchUpImageView))
        imageView.addGestureRecognizer(tapGesture)
        imageView.isUserInteractionEnabled = true // 터치 허용
        imageView.contentMode = .scaleAspectFill // 이미지 뷰에 꽉 채우도록 설정
        imageView.clipsToBounds = true // 이미지 뷰의 경계를 넘어가는 이미지는 잘라냄
    }
    
    // 전체 뷰에 터치 제스처 설정
    func touchGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        tapGesture.delegate = self
        self.view.addGestureRecognizer(tapGesture)
    }
    
    // 슬라이더 값 변경에 따라 레이블 업데이트
    @objc func sliderValueChanged() {
        ratingLabel.text = "\(Int(ratingSlider.value))"
    }
    
    // 키보드 닫기
    @objc func handleTap() {
        view.endEditing(true)
    }
    
    // 이미지뷰 터치 시 호출되는 메서드
    @objc func touchUpImageView() {
        print("이미지뷰 터치")
        // 사진 라이브러리에서 이미지 선택
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        present(picker, animated: true, completion: nil)
    }
    
    // 이미지 선택이 완료되면 호출되는 메서드
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            imageView.image = image
        }
    }
    
    // MARK: - SetUpTextView

    func setUpTextView() {
        // 텍스트 뷰의 레이어 속성 설정
        noseTextView.layer.borderWidth = 1.0 // 윤곽선 두께 설정
        noseTextView.layer.borderColor = UIColor.gray.cgColor // 윤곽선 색상 설정
        noseTextView.layer.cornerRadius = 8.0 // 윤곽선의 모서리 둥글기 설정 (원하는 값으로 변경)
//        // 텍스트 뷰의 그림자 설정
//        noseTextView.layer.shadowColor = UIColor.purple.cgColor // 그림자 색상 설정
//        noseTextView.layer.shadowOffset = CGSize(width: 0, height: 2) // 그림자의 위치와 크기 설정 (가로로 0, 세로로 2)
//        noseTextView.layer.shadowRadius = 4.0 // 그림자의 반경 설정
//        noseTextView.layer.shadowOpacity = 0.5 // 그림자의 투명도 설정
//        // 텍스트 뷰의 마스크 설정 해제
//        noseTextView.layer.masksToBounds = false
        
        // 텍스트 뷰의 레이어 속성 설정
        palateTextView.layer.borderWidth = 1.0 // 윤곽선 두께 설정
        palateTextView.layer.borderColor = UIColor.gray.cgColor // 윤곽선 색상 설정
        palateTextView.layer.cornerRadius = 8.0 // 윤곽선의 모서리 둥글기 설정 (원하는 값으로 변경)

        
        // 텍스트 뷰의 레이어 속성 설정
        finishTextView.layer.borderWidth = 1.0 // 윤곽선 두께 설정
        finishTextView.layer.borderColor = UIColor.gray.cgColor // 윤곽선 색상 설정
        finishTextView.layer.cornerRadius = 8.0 // 윤곽선의 모서리 둥글기 설정 (원하는 값으로 변경)

    }
    
    // MARK: - SetUpTextField
    
    func setUpTextField() {
        nameField.layer.borderWidth = 1.0 // 윤곽선 두께 설정
        nameField.layer.borderColor = UIColor.gray.cgColor // 윤곽선 색상 설정
        //nameField.layer.cornerRadius = 8.0 // 윤곽선의 모서리 둥글기 설정 (원하는 값으로 변경)
        // 텍스트 뷰의 그림자 설정
//        nameField.layer.shadowColor = UIColor.purple.cgColor // 그림자 색상 설정
//        nameField.layer.shadowOffset = CGSize(width: 0, height: 2) // 그림자의 위치와 크기 설정 (가로로 0, 세로로 2)
//        nameField.layer.shadowRadius = 4.0 // 그림자의 반경 설정
//        nameField.layer.shadowOpacity = 0.5 // 그림자의 투명도 설정
        
        distilleryField.layer.borderWidth = 1.0 // 윤곽선 두께 설정
        distilleryField.layer.borderColor = UIColor.gray.cgColor // 윤곽선 색상 설정
        
        ABVField.layer.borderWidth = 1.0 // 윤곽선 두께 설정
        ABVField.layer.borderColor = UIColor.gray.cgColor // 윤곽선 색상 설정
        
        agedField.layer.borderWidth = 1.0 // 윤곽선 두께 설정
        agedField.layer.borderColor = UIColor.gray.cgColor // 윤곽선 색상 설정
        
        caskField.layer.borderWidth = 1.0 // 윤곽선 두께 설정
        caskField.layer.borderColor = UIColor.gray.cgColor // 윤곽선 색상 설정
    }
}



    // MARK: - 이미지 회전 막기
    
    // 이미지를 올바르게 회전시켜주는 메서드
    extension UIImage {
        func fixOrientation() -> UIImage {
            // 이미지가 올바르게 회전되어 있는 경우
            if self.imageOrientation == .up {
                return self
            }
            
            var transform = CGAffineTransform.identity
            
            switch self.imageOrientation {
            case .down, .downMirrored:
                transform = transform.translatedBy(x: self.size.width, y: self.size.height)
                transform = transform.rotated(by: .pi)
            case .left, .leftMirrored:
                transform = transform.translatedBy(x: self.size.width, y: 0)
                transform = transform.rotated(by: .pi / 2)
            case .right, .rightMirrored:
                transform = transform.translatedBy(x: 0, y: self.size.height)
                transform = transform.rotated(by: -.pi / 2)
            default:
                break
            }
            
            switch self.imageOrientation {
            case .upMirrored, .downMirrored:
                transform = transform.translatedBy(x: self.size.width, y: 0)
                transform = transform.scaledBy(x: -1, y: 1)
            case .leftMirrored, .rightMirrored:
                transform = transform.translatedBy(x: self.size.height, y: 0)
                transform = transform.scaledBy(x: -1, y: 1)
            default:
                break
            }
            
            guard let cgImage = self.cgImage,
                  let colorSpace = cgImage.colorSpace,
                  let context = CGContext(data: nil, width: Int(self.size.width), height: Int(self.size.height), bitsPerComponent: cgImage.bitsPerComponent, bytesPerRow: 0, space: colorSpace, bitmapInfo: cgImage.bitmapInfo.rawValue) else {
                return self
            }
            
            context.concatenate(transform)
            
            switch self.imageOrientation {
            case .left, .leftMirrored, .right, .rightMirrored:
                context.draw(cgImage, in: CGRect(x: 0, y: 0, width: self.size.height, height: self.size.width))
            default:
                context.draw(cgImage, in: CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height))
            }
            
            guard let newCGImage = context.makeImage() else {
                return self
            }
            
            return UIImage(cgImage: newCGImage)
        }
    }

