import Kitura
import LoggerAPI
import HeliumLogger
import SwiftDIHLP
import Foundation

final class GamesController {
    let gameRepository: GameRepository

    init(router: Router, gameRepository: GameRepository) {
        self.gameRepository = gameRepository
        createRoutes(router: router)
    }

    private func createRoutes(router: Router) {
        router.all("/games", middleware: BodyParser())
        router.get("/games", handler: index)
        router.get("/games/:gameId", handler: show)
        router.post("/games", handler: create)
        router.delete("/games", handler: destroyAll)
    }

    private func index(request: RouterRequest, response: RouterResponse, next: () -> Void) throws {
        defer { next() }

        Log.info("GET /games")
        FetchGamesUseCase(observer: RPSGameHistoryObserver(response: response),
                          repo: gameRepository)
            .execute()
    }

    private func show(request: RouterRequest, response: RouterResponse, next: () -> Void) throws {
        defer { next() }

        guard let id = request.parameters["gameId"], let uuid = UUID(uuidString: id) else {
            try response.status(.badRequest).end()
            return
        }

        Log.info("GET /games\(uuid.uuidString)")
        FetchGameByIdUseCase(id: uuid,
                             observer: RPSGameHistoryObserver(response: response),
                             repo: gameRepository)
            .execute()
    }

    private func create(request: RouterRequest, response: RouterResponse, next: () -> Void) throws {
        defer { next() }

        guard let values = request.body else {
            try response.status(.badRequest).end()
            return
        }

        guard case .json(let body) = values else {
            try response.status(.badRequest).end()
            return
        }

        Log.info("POST /games")
        if let p1 = body["player1"].string, let p2 = body["player2"].string {
            PlayUseCase(p1: p1,
                        p2: p2,
                        observer: RPSGameObserver(response: response),
                        repo: gameRepository)
                .execute()
        }
    }

    private func destroyAll(request: RouterRequest, response: RouterResponse, next: () -> Void) throws {
        defer { next() }

        Log.info("DELETE /games")
        gameRepository.deleteAll()
        try response.status(.OK).end()
    }
}
