//
//  ImageCache.swift
//  Waves
//
//  Created by Dallas Hoelscher on 5/15/19.
//  Copyright © 2019 Waves. All rights reserved.

import Foundation
import UIKit

class ImageCache {
    static let shared = ImageCache()
    private init() {}
    //Mark - Variables for cache
    //Switched this to a dictionary of String : AnyObject becuase cache clears too often
    var imageCache = [String : AnyObject]()

    //MARK - Cache handling
    //Mark - Loading cached images

    func removeImageFromCache(key: String) {
        imageCache.removeValue(forKey: key)
    }

    func loadImageUsingCacheWithURLString(_ urlString: String, completion: @escaping ((UIImage?, String) -> Void))
    {

        guard let url = URL(string: urlString) else
        {
            completion(nil, urlString)
            return
        }
        //Check cache for image
        if let cachedImage = imageCache[urlString] as? UIImage
        {
            completion(cachedImage, urlString)
            //self.image = cachedImage
            return
        }

        URLSession.shared.dataTask(with: url, completionHandler: {
            (data, response, error) in

            if let error = error    {
                print(error)
                completion(nil, urlString)
            }

            DispatchQueue.main.async
                {
                    if let data = data, let downloadedImage = UIImage(data: data)
                    {
                        self.imageCache[urlString] = downloadedImage
                        completion(downloadedImage, urlString)
                    }
            }
        }).resume()
    }

    func tryToGetCachedImage(fromLink link: String) -> UIImage?{
        return imageCache[link] as? UIImage
    }

}

