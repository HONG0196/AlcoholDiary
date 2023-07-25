//
//  ViewController.swift
//  Alcohol Diary
//
//  Created by 양홍찬 on 2023/07/12.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var alcoholCollection: UICollectionView!
    
    // CoreDataManager를 관리하기 위해 의존성 주입 사용
    private let alcoholManager = CoreDataManager.shared
    private var alcoholList: [AlcoholData] = [] // 전체 알코올 데이터를 저장할 배열
    
    let searchController = UISearchController(searchResultsController: nil)
    var filteredAlcoholList: [AlcoholData] = [] // 검색 결과를 저장할 배열
    
    // 선택된 셀들을 저장할 배열
    var selectedCells: [IndexPath] = []
    
    // 편집 모드인지 여부를 저장하는 변수
    var isEditingMode: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        loadData()
        
        // 탭 제스처를 추가하고 delegate를 뷰 컨트롤러로 설정
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture))
        tapGesture.delegate = self
        view.addGestureRecognizer(tapGesture)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadData()
        
    }
    
    // MARK: - Setup UI
    
    private func setupUI() {
        alcoholCollection.delegate = self
        alcoholCollection.dataSource = self
        
        alcoholCollection.register(UINib(nibName: "CollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "alcoholCell")
        
        setupNavigationBar()
        setupSearchBar()
    }
    
    private func setupNavigationBar() {
        title = "Alcohol Diary"
        navigationItem.hidesSearchBarWhenScrolling = true
        
        // 추가: 플러스 버튼
        let plusButton = UIBarButtonItem(image: UIImage(systemName: "square.and.pencil"), style: .plain, target: self, action: #selector(plusButtonTapped))
        plusButton.tintColor = .purple
        navigationItem.rightBarButtonItem = plusButton
        
        // 추가: 수정 버튼
        let editButton = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(editButtonTapped))
        editButton.tintColor = .purple
        navigationItem.leftBarButtonItem = editButton
    }
    
    private func setupSearchBar() {
        // 검색 바 설정
        navigationItem.searchController = searchController
        searchController.searchBar.delegate = self
        searchController.searchBar.autocapitalizationType = .none
        searchController.hidesNavigationBarDuringPresentation = false
        navigationItem.hidesSearchBarWhenScrolling = false
    }
    
    // MARK: - Button Actions
    
    @objc private func plusButtonTapped() {
        // 추가 버튼을 누르면 세그웨이 실행하여 상세 화면으로 이동
        performSegue(withIdentifier: "DetailVC", sender: nil)
    }
    
    @objc private func editButtonTapped() {
        // 편집 버튼을 눌렀을 때 편집 모드 전환
        isEditingMode = !isEditingMode
        
        // 선택된 셀 배열 초기화
        selectedCells.removeAll()
        
        // 전체 셀을 선택 해제
        for indexPath in alcoholCollection.indexPathsForSelectedItems ?? [] {
            alcoholCollection.deselectItem(at: indexPath, animated: false)
        }
        
        // 컬렉션 뷰의 편집 모드 설정
        alcoholCollection.allowsMultipleSelection = isEditingMode
        alcoholCollection.reloadData()
        
        // 편집 모드일 때 버튼 변경
        if isEditingMode {
            navigationItem.leftBarButtonItem?.title = "Cancel"
            navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(deleteButtonTapped))
            navigationItem.rightBarButtonItem?.tintColor = .red
        } else {
            navigationItem.leftBarButtonItem?.title = "Edit"
            navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "square.and.pencil"), style: .plain, target: self, action: #selector(plusButtonTapped))
            navigationItem.rightBarButtonItem?.tintColor = .purple
        }
    }
    
    @objc private func deleteButtonTapped() {
        deleteSelectedCells()
    }
    // 선택된 셀 삭제
    private func deleteSelectedCells() {
        // 선택된 셀이 없으면 리턴
        guard !selectedCells.isEmpty else {
            return
        }
        
        // 삭제할 indexPath들을 저장할 배열
        var indexPathsToRemove: [IndexPath] = []
        
        // 역순으로 처리해야 인덱스가 꼬이지 않습니다.
        for indexPath in selectedCells.reversed() {
            let alcoholData: AlcoholData
            
            if searchController.isActive && !filteredAlcoholList.isEmpty {
                // 검색 결과가 있을 경우, filteredAlcoholList 배열에서 데이터 가져옴
                guard indexPath.row < filteredAlcoholList.count else {
                    continue // 검색 결과 배열의 인덱스를 벗어나면 스킵 (유효하지 않은 indexPath)
                }
                alcoholData = filteredAlcoholList[indexPath.row]
            } else {
                // 검색 결과가 없을 경우, 전체 데이터 배열에서 데이터 가져옴
                guard indexPath.row < alcoholList.count else {
                    continue // 전체 데이터 배열의 인덱스를 벗어나면 스킵 (유효하지 않은 indexPath)
                }
                alcoholData = alcoholList[indexPath.row]
            }
            
            // Core Data에서 데이터 삭제
            alcoholManager.deleteAlcohol(data: alcoholData) { [weak self] result in
                switch result {
                case .success:
                    // 삭제 성공 시 삭제할 indexPath 추가
                    indexPathsToRemove.append(indexPath)
                case .failure(let error):
                    print("알코올 데이터 삭제 에러: \(error)")
                }
            }
        }
        
        // 선택된 셀 배열 비우기
        selectedCells.removeAll()
        
        // 검색 결과가 있을 경우 filteredAlcoholList에서 삭제
        if searchController.isActive && !filteredAlcoholList.isEmpty {
            let indexesToRemove = indexPathsToRemove.map { $0.row }.sorted(by: >)
            for index in indexesToRemove {
                filteredAlcoholList.remove(at: index)
            }
        } else {
            // 검색 결과가 없을 경우 alcoholList에서 삭제
            let indexesToRemove = indexPathsToRemove.map { $0.row }.sorted(by: >)
            for index in indexesToRemove {
                alcoholList.remove(at: index)
            }
        }
        
        // 컬렉션 뷰에서 삭제할 indexPath들 제거
        alcoholCollection.deleteItems(at: indexPathsToRemove)
        
        // 편집 모드 종료
        isEditingMode = false
        
        // 컬렉션 뷰 다시 로드
        alcoholCollection.reloadData()
        
        // 편집 모드일 때 버튼 변경
        navigationItem.leftBarButtonItem?.title = "Edit"
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "square.and.pencil"), style: .plain, target: self, action: #selector(plusButtonTapped))
        navigationItem.rightBarButtonItem?.tintColor = .purple
    }
    
    // MARK: - Tap Gesture Handler
    
    @objc private func handleTapGesture() {
        // 다른 곳을 터치했을 때, 서치바가 포커스를 가지고 있다면 포커스 해제
        if searchController.searchBar.isFirstResponder {
            searchController.searchBar.resignFirstResponder()
        }
    }
    
    
    
    
    
    // MARK: - Load Data
    
    private func loadData() {
        if searchController.isActive && !filteredAlcoholList.isEmpty {
            // 검색 중이면서 검색 결과가 있을 경우, 검색 결과 데이터를 로드
            alcoholList = filteredAlcoholList
        } else {
            // 검색 중이 아니거나 검색 결과가 없을 경우, 전체 데이터를 로드
            alcoholList = alcoholManager.getAlcoholListFromCoreData()
        }
        alcoholCollection.reloadData()
    }
}

// MARK: - UICollectionViewDataSource

extension ViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // 검색 결과가 있을 경우 해당 배열의 개수 반환, 없을 경우 전체 데이터 개수 반환
        if searchController.isActive && !filteredAlcoholList.isEmpty {
            return filteredAlcoholList.count
        } else {
            return alcoholList.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "alcoholCell", for: indexPath) as! CollectionViewCell
        
        // 셀에 표시할 데이터 가져오기
        let alcoholData: AlcoholData
        if searchController.isActive && !filteredAlcoholList.isEmpty {
            // 검색 결과가 있을 경우 검색 결과 배열에서 데이터 가져옴
            alcoholData = filteredAlcoholList[indexPath.row]
        } else {
            // 검색 결과가 없을 경우 전체 데이터 배열에서 데이터 가져옴
            alcoholData = alcoholList[indexPath.row]
        }
        
        // 이미지를 표시 (이미지가 Data 타입으로 저장되어 있으므로 비동기 로딩 불필요)
        if let imageData = alcoholData.image, let image = UIImage(data: imageData) {
            cell.cellimage.image = image
        }
        
        // 셀에 모델 전달
        cell.alData = alcoholData
        
        // 편집 모드일 때 선택된 셀을 표시
        if isEditingMode {
            if selectedCells.contains(indexPath) {
                cell.contentView.layer.borderWidth = 3
                cell.contentView.layer.borderColor = UIColor.purple.cgColor
            } else {
                cell.contentView.layer.borderWidth = 0
            }
        } else {
            cell.contentView.layer.borderWidth = 0
        }
        
        return cell
    }
}

// MARK: - UICollectionViewDelegate

extension ViewController: UICollectionViewDelegate {
    // 셀 선택 처리
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if isEditingMode {
            // 편집 모드일 때 선택한 셀을 배열에 저장
            if let index = selectedCells.firstIndex(of: indexPath) {
                selectedCells.remove(at: index)
            } else {
                selectedCells.append(indexPath)
            }
            collectionView.reloadItems(at: [indexPath]) // 셀의 외형을 업데이트
        } else {
            // 편집 모드가 아닐 때만 세그웨이 수행 (상세 화면으로 이동)
            performSegue(withIdentifier: "DetailVC", sender: indexPath)
        }
    }
    
    // (세그웨이를 실행할 때) 실제 데이터 전달
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "DetailVC" {
            let detailVC = segue.destination as! DetailViewController
            
            if let indexPath = sender as? IndexPath {
                // 선택한 셀의 인덱스 경로를 기반으로 해당 셀의 데이터를 가져옴
                var alcoholData: AlcoholData
                
                if searchController.isActive && !filteredAlcoholList.isEmpty {
                    // 검색 결과가 있을 경우, filteredAlcoholList 배열에서 데이터 가져옴
                    alcoholData = filteredAlcoholList[indexPath.row]
                } else {
                    // 검색 결과가 없을 경우, 전체 데이터 배열에서 데이터 가져옴
                    alcoholData = alcoholList[indexPath.row]
                }
                
                detailVC.alData = alcoholData
                detailVC.selectedIndexPath = indexPath
            }
        }
    }
    
    // 셀의 크기 설정
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let margin: CGFloat = 20
        let width: CGFloat = (collectionView.bounds.width - margin) / 2
        let height: CGFloat = width * 1.4
        return CGSize(width: width, height: height)
    }
}

// MARK: - UISearchBarDelegate

extension ViewController: UISearchBarDelegate {
    // SearchBar delegate 메서드
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        navigationItem.leftBarButtonItem?.isEnabled = false
        // 원하는 취소 버튼 이름으로 변경
        searchBar.setValue("취소", forKey: "cancelButtonText")
        // 검색 창에 텍스트가 없을 때에만 편집 모드로 진입
        return true
    }
    
    // 검색어가 변경될 때마다 호출되는 메서드
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        //navigationItem.leftBarButtonItem?.isEnabled = false
        // CoreDataManager의 searchAlcoholData 메서드를 호출하여 검색 결과를 가져옴
        alcoholManager.searchAlcoholData(with: searchText) { [weak self] filteredAlcoholList in
            // 검색 결과를 받은 후에 filteredAlcoholList에 저장하고 데이터를 로드해야 셀이 갱신됩니다.
            self?.filteredAlcoholList = filteredAlcoholList
            self?.loadData()
        }

    }
    
    // 검색 취소 버튼을 클릭했을 때 호출되는 메서드
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        // 검색 창에 내용을 지우고 모든 셀을 표시
        searchBar.text = ""
        filteredAlcoholList = []
        // 서치바 포커스 해제
        searchBar.resignFirstResponder()
        // 검색 바 비활성화
        searchController.isActive = false
        // 전체 셀을 보여줍니다.
        loadData()
        
        // 편집 버튼 보여주기
        //navigationItem.leftBarButtonItem?.title = "Edit"
        navigationItem.leftBarButtonItem?.isEnabled = true
    }
}


// MARK: - UIGestureRecognizerDelegate

extension ViewController: UIGestureRecognizerDelegate {
    // 탭 제스처를 받을 때 서치바가 포커스를 가지고 있다면 true 반환하여 제스처를 처리
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return searchController.searchBar.isFirstResponder
    }
}
