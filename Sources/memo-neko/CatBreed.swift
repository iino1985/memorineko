import Foundation

// MARK: - 猫の種類（見た目のバリエーション。表情ステージとは独立して選べる）

enum CatBreed: Int, CaseIterable {
    case calico = 0    // 三毛猫（既存・デフォルト）
    case black = 1     // 黒猫
    case tabby = 2     // 茶トラ
    case hachiware = 3 // ハチワレ
    case exotic = 4    // エキゾチック（潰れ顔）
    case custom = 5    // ユーザーがアップロードした画像

    var menuLabel: String {
        switch self {
        case .calico: return "三毛猫"
        case .black: return "黒猫"
        case .tabby: return "茶トラ"
        case .hachiware: return "ハチワレ"
        case .exotic: return "エキゾチック"
        case .custom: return "カスタム"
        }
    }

    // 画像ファイル名のプレフィックス。三毛猫は既存アセットとの後方互換のため無印の"cat"のまま。
    var fileNamePrefix: String {
        switch self {
        case .calico: return "cat"
        case .black: return "cat_black"
        case .tabby: return "cat_tabby"
        case .hachiware: return "cat_hachiware"
        case .exotic: return "cat_exotic"
        case .custom: return "cat_custom" // 実際にはcustomImagesDirectory()から読むため未使用
        }
    }

    // メニューバー表示時の拡大率。三毛猫の旧画像はキャンバスに余白が多いため1.3倍で大きく見せる。
    // 黒猫・茶トラ・ハチワレはキャンバスの95%まで描かれた新仕様の画像なので等倍でよい
    // （拡大すると耳やヒゲが切れる）。三毛猫を将来同じ仕様の画像に差し替えたらこの分岐は不要になる。
    var overscan: CGFloat {
        switch self {
        case .calico: return 1.3
        case .black, .tabby, .hachiware, .exotic: return 1.15
        case .custom: return 1.0 // ユーザー画像はどんな余白か分からないので拡大しない
        }
    }
}

extension CatStage {
    // ファイル名に使う英字サフィックス（cat_<品種>_<この値>.png）
    var fileSuffix: String {
        switch self {
        case .slim: return "slim"
        case .normal: return "normal"
        case .chubby: return "chubby"
        case .plump: return "plump"
        case .stuffed: return "stuffed"
        }
    }
}
