//
//  DLoading.swift
//  Swift Concurrency
//
//  Created by 吴丹 on 2022/8/17.
//

import Foundation
import UIKit
import NVActivityIndicatorView

class DLoading {
    private var keyWindow: UIWindow? {
        var window: UIWindow?
        
        if #available(iOS 15, *) {
            window = UIApplication.shared.connectedScenes
                .filter({$0.activationState == .foregroundInactive})
                .map({ $0 as? UIWindowScene })
                .compactMap({ $0 })
                .last?.windows
                .last
        } else if #available(iOS 13.0, *) {
            window = UIApplication.shared.connectedScenes
                .filter({ $0.activationState == .foregroundActive })
                .map({ $0 as? UIWindowScene })
                .compactMap({ $0 })
                .last?.windows
                .filter({ $0.isKeyWindow })
                .last
        } else {
            window = UIApplication.shared.keyWindow
        }
        return window
    }
    
    private static let loading = DLoading()

    private lazy var maskView: UIButton = {
        let b = UIButton()
        b.addTarget(self, action: #selector(didTappedBgGroundView), for: .touchUpInside)
        return b
    }()
    
    private lazy var backgroundView: UIView = {
        let v = UIView()
        return v
    }()
    
    private lazy var titleLabel: UILabel = {
        let lb = UILabel()
        lb.textColor = .white
        lb.textAlignment = .center
        return lb
    }()
    
    private lazy var loadingView: NVActivityIndicatorView = {
        let v = NVActivityIndicatorView(frame: .zero)
        v.startAnimating()
        v.color = .white
        v.type = .circleStrokeSpin
        return v
    }()
    
    private var maskTappAction: MaskTappAction?
    
    private var parentView: UIView?
    
    typealias MaskTappAction = () -> ()
    
    @objc private func didTappedBgGroundView() {
        if let action = maskTappAction {
            action()
        }
    }
    
    private func showLoading(titleColor: UIColor = .white,
                             loadingColor: UIColor = .white,
                             font: UIFont = .systemFont(ofSize: 14, weight: .medium),
                             backgroundColor: UIColor = .init(white: 0, alpha: 0.8),
                             maskColor: UIColor = .init(white: 0, alpha: 0.3),
                             title: String = "",
                             type: NVActivityIndicatorType = .circleStrokeSpin,
                             inView: UIView?,
                             maskTap:MaskTappAction?) {
                             
        loadingView.type = type
        titleLabel.textColor = titleColor
        loadingView.color = loadingColor
        backgroundView.backgroundColor = backgroundColor
        backgroundView.layer.cornerRadius = 5
        maskTappAction = maskTap
        maskView.backgroundColor = maskColor

        if let inView = inView {
            inView.addSubview(backgroundView)
            parentView = inView
            backgroundView.center = inView.center
        } else {
            if let keyWindow = keyWindow {
                parentView = keyWindow
                keyWindow.addSubview(maskView)
                maskView.frame = UIScreen.main.bounds
                maskView.addSubview(backgroundView)
                backgroundView.center = maskView.center
            }
        }
        
        
        backgroundView.addSubview(loadingView)
        if (title.count > 0) {
            let size = textSize(text: title, font: font, maxWidth: UIScreen.main.bounds.width * 0.8)
            backgroundView.addSubview(titleLabel)
            titleLabel.frame = CGRect(x: 10, y: 50, width: size.width, height: size.height)
            backgroundView.bounds = CGRect(x: 0, y: 0, width: size.width + 20, height: 60 + size.height)
        } else {
            backgroundView.bounds = CGRect(x: 0, y: 0, width: 60, height: 60)
        }
        
        loadingView.bounds = CGRect(x: 0, y: 0, width: 30, height: 30)
        loadingView.center = CGPoint(x: backgroundView.frame.width / 2, y: 15 + 15)
    }
    
    private func showToast(titleColor: UIColor = .white,
                           font: UIFont = .systemFont(ofSize: 14, weight: .medium),
                           backgroundColor: UIColor = .init(white: 0, alpha: 0.8),
                           maskColor: UIColor = .init(white: 0, alpha: 0.3),
                           title: String = "",
                           delay: TimeInterval = 1.5,
                           inView: UIView?,
                           maskTap:MaskTappAction?) {
                             
        titleLabel.textColor = titleColor
        backgroundView.backgroundColor = backgroundColor
        backgroundView.layer.cornerRadius = 5
        maskTappAction = maskTap
        maskView.backgroundColor = maskColor
        
        if let inView = inView {
            inView.addSubview(backgroundView)
            parentView = inView
            backgroundView.center = inView.center
        } else {
            if let keyWindow = keyWindow {
                parentView = keyWindow
                keyWindow.addSubview(maskView)
                maskView.frame = UIScreen.main.bounds
                maskView.addSubview(backgroundView)
                backgroundView.center = maskView.center
            }
        }
        
        let size = textSize(text: title, font: font, maxWidth: UIScreen.main.bounds.width * 0.8)
        backgroundView.addSubview(titleLabel)
        titleLabel.frame = CGRect(x: 10, y: 10, width: size.width, height: size.height)
        backgroundView.bounds = CGRect(x: 0, y: 0, width: size.width + 20, height: 20 + size.height)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: DispatchWorkItem(block: { [weak self] in
            guard let self = self else { return }
            self.maskView.removeFromSuperview()
            self.backgroundView.removeFromSuperview()
        }))
    }
    
    private func textSize(text: String, font: UIFont, maxWidth: CGFloat) -> CGSize {
        titleLabel.numberOfLines = 0
        titleLabel.font = font
        titleLabel.text = text
        return titleLabel.sizeThatFits(CGSize(width: maxWidth, height: .infinity))
    }
    
    private func hidenLoading(delay: TimeInterval = 0) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: DispatchWorkItem(block: { [weak self] in
            guard let self = self else { return }
            self.maskView.removeFromSuperview()
            self.backgroundView.removeFromSuperview()
        }))
    }
    
    
    
    public class func showLoading(titleColor: UIColor = .white,
                                  loadingColor: UIColor = .white,
                                  font: UIFont = .systemFont(ofSize: 14, weight: .medium),
                                  backgroundColor: UIColor = .init(white: 0, alpha: 0.8),
                                  maskColor: UIColor = .init(white: 0, alpha: 0.3),
                                  title: String = "",
                                  type: NVActivityIndicatorType = .circleStrokeSpin,
                                  inView: UIView? = DLoading.loading.keyWindow,
                                  maskTap:MaskTappAction?) {
        DLoading.loading.showLoading(titleColor: titleColor, loadingColor:loadingColor, font: font, backgroundColor: backgroundColor, maskColor: maskColor, title: title, type: type, inView: inView, maskTap: maskTap)
    }
    
    
    public class func showToast(titleColor: UIColor = .white,
                                font: UIFont = .systemFont(ofSize: 14, weight: .medium),
                                backgroundColor: UIColor = .init(white: 0, alpha: 0.8),
                                maskColor: UIColor = .init(white: 0, alpha: 0.3),
                                title: String = "",
                                delay: TimeInterval = 1.5,
                                inView: UIView? = DLoading.loading.keyWindow,
                                maskTap:MaskTappAction? = nil) {
        
        DLoading.loading.showToast(titleColor: titleColor, font: font, backgroundColor: backgroundColor, maskColor: maskColor, title: title, delay: delay, inView: inView, maskTap: maskTap)
    }
    
    public class func hidenLoading(delay: TimeInterval = 0) {
        DLoading.loading.hidenLoading(delay: delay)
    }
}
