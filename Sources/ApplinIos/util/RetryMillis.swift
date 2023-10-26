class RetryMillis {
    let millis: [Int]
    init(millis: [Int]) {
        if millis.isEmpty {
            self.millis = [0]
        } else {
            self.millis = millis
        }
    }

    func get(attemptNum: Int) -> Int {
        let ms = Double(self.millis.get(attemptNum) ?? self.millis.last!)
        let range = attemptNum == 0 ? (0.95 * ms)...(1.05 * ms) : (0.5 * ms)...(1.5 * ms)
        return Int(Double.random(in: range))
    }
}
