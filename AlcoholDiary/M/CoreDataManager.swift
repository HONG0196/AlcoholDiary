//
//  CoreDataManager.swift
//  Alcohol Diary
//
//  Created by 양홍찬 on 2023/07/18.
//

import UIKit
import CoreData

final class CoreDataManager: NSObject, NSFetchedResultsControllerDelegate {
    
    // MARK: - Singleton
    
    static let shared = CoreDataManager()
    private override init() {}
    
    // MARK: - Properties
    
    private let appDelegate = UIApplication.shared.delegate as? AppDelegate
    private lazy var context: NSManagedObjectContext? = {
        return appDelegate?.persistentContainer.viewContext
    }()
    
    let modelName: String = "AlcoholData"
    
    // 이미지 캐시를 위한 딕셔너리 (URL과 이미지의 쌍으로 저장)
    private var imageCache: [String: UIImage] = [:]
    
    // MARK: - NSFetchedResultsController
    
    // CoreData에서 정렬된 결과를 가져오기 위한 NSFetchedResultsController 설정
    private lazy var fetchedResultsController: NSFetchedResultsController<AlcoholData> = {
        let request: NSFetchRequest<AlcoholData> = AlcoholData.fetchRequest()
        let dateOrder = NSSortDescriptor(key: "date", ascending: false)
        request.sortDescriptors = [dateOrder]
        
        let controller = NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: context!,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        controller.delegate = self
        
        return controller
    }()
    
    // 이미지를 캐시에 저장하고, 이미지 URL을 키로 사용하여 딕셔너리에 저장
    func cacheImage(_ image: UIImage, forURL url: String) {
        imageCache[url] = image
    }
    
    // 이미지 캐시에서 이미지를 가져오기 위한 메서드
    func loadImageFromCache(with url: String) -> UIImage? {
        return imageCache[url]
    }
    
    // 이미지를 로드하여 캐시에 저장
    func loadImageAsync(with url: URL, completion: @escaping (UIImage?) -> Void) {
        // 이미지가 캐시에 있는 경우, 캐시에서 이미지를 가져옴
        if let cachedImage = imageCache[url.absoluteString] {
            completion(cachedImage)
            return
        }
        
        // 캐시에 없는 경우, 이미지를 다운로드하여 캐시에 저장
        DispatchQueue.global().async {
            if let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
                DispatchQueue.main.async { [weak self] in
                    // 이미지 다운로드가 완료되면, 캐시에 이미지를 저장하고 반환
                    self?.cacheImage(image, forURL: url.absoluteString)
                    completion(image)
                }
            } else {
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }
    }
    
    // MARK: - Public Methods
    
    // Core Data에서 저장된 모든 알콜 데이터 가져오기
    func getAlcoholListFromCoreData() -> [AlcoholData] {
        guard let context = context else {
            return []
        }
        
        do {
            try fetchedResultsController.performFetch()
            return fetchedResultsController.fetchedObjects ?? []
        } catch {
            print("Error fetching data from Core Data: \(error)")
            return []
        }
    }
    // MARK: - search

    // Core Data에서 검색어 기준으로 알콜 데이터 검색하기 
    func searchAlcoholData(with searchText: String, completion: @escaping ([AlcoholData]) -> Void) {
        guard let context = context else {
            completion([])
            return
        }

        let request: NSFetchRequest<AlcoholData> = AlcoholData.fetchRequest()
        let dateOrder = NSSortDescriptor(key: "date", ascending: false)
        request.sortDescriptors = [dateOrder]

        let predicate: NSPredicate?
        if !searchText.isEmpty {
            predicate = NSPredicate(format: "name CONTAINS[cd] %@", searchText)
        } else {
            predicate = nil
        }
        request.predicate = predicate

        do {
            let results = try context.fetch(request)
            completion(results)
        } catch {
            print("Error fetching data from Core Data: \(error)")
            completion([])
        }
    }
    
    // Core Data에 데이터 생성하기
    func saveAlcoholData(alImage: Data?, nameText: String?, distilleryText: String?, abvText: String?, agedText: String?, caskText: String?, noseText: String?, palateText: String?, finishText: String?, rating: String?, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let context = context,
              let entity = NSEntityDescription.entity(forEntityName: modelName, in: context) else {
            completion(.failure(CoreDataError.invalidContext))
            return
        }
        
        let alcoholData = AlcoholData(entity: entity, insertInto: context)
        
        // 이미지를 바이너리 데이터로 저장
        alcoholData.image = alImage
        
        alcoholData.name = nameText
        alcoholData.distillery = distilleryText
        alcoholData.abv = abvText
        alcoholData.aged = agedText
        alcoholData.cask = caskText
        alcoholData.nose = noseText
        alcoholData.palate = palateText
        alcoholData.finish = finishText
        alcoholData.ratingScore = rating
        alcoholData.date = Date()
        
        do {
            try context.save()
            completion(.success(()))
        } catch {
            completion(.failure(error))
        }
    }

    
    // Core Data에서 데이터 삭제하기
    func deleteAlcohol(data: AlcoholData, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let date = data.date,
              let context = context else {
            completion(.failure(CoreDataError.invalidContext))
            return
        }
        
        let request: NSFetchRequest<AlcoholData> = AlcoholData.fetchRequest()
        request.predicate = NSPredicate(format: "date = %@", date as CVarArg)
        
        do {
            if let fetchedAlcoholList = try context.fetch(request).first {
                context.delete(fetchedAlcoholList)
                
                if context.hasChanges {
                    try context.save()
                }
            }
            completion(.success(()))
        } catch {
            completion(.failure(error))
        }
    }
    
    // Core Data에서 데이터 수정하기
    func updateAlcohol(newAlcoholData: AlcoholData, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let date = newAlcoholData.date else {
            completion(.failure(CoreDataError.invalidContext))
            return
        }
        
        if let context = context {
            let request = NSFetchRequest<NSManagedObject>(entityName: modelName)
            request.predicate = NSPredicate(format: "date = %@", date as CVarArg)
            
            do {
                if let fetchedAlcoholList = try context.fetch(request) as? [AlcoholData], var targetAlcohol = fetchedAlcoholList.first {
                    targetAlcohol = newAlcoholData
                    
                    if context.hasChanges {
                        do {
                            try context.save()
                            completion(.success(()))
                        } catch {
                            completion(.failure(error))
                        }
                    }
                }
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - NSFetchedResultsControllerDelegate
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        // 검색 결과가 변경되었을 때 필요한 처리를 여기에 추가할 수 있습니다.
        // 예를 들면, 컬렉션 뷰를 업데이트하는 등의 작업을 수행할 수 있습니다.
        
    }
}

// MARK: - 에러 처리

enum CoreDataError: Error {
    case invalidContext
}
