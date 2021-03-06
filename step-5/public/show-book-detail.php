<?php
/**
 * PHP version 7
 *
 * This source file is subject to the license that is bundled with this package in the file LICENSE.
 */
require __DIR__ . '/../vendor/autoload.php';
require __DIR__ . '/../config/environment.php';
require __DIR__ . '/../config/options.php';

use Zend\Db\{
    Sql\Select,
    TableGateway\TableGateway
};
use Zend\Diactoros\{
    Response\HtmlResponse,
    Response\SapiEmitter,
    ServerRequestFactory
};

try {
    $request = ServerRequestFactory::fromGlobals();
    /** @var \Zend\Db\Adapter\Adapter $connection */
    $connection = require __DIR__ . '/../config/connection.php';
    $booksTable = new TableGateway(['b' => 'book'], $connection);
    $bookId = (int) $request->getQueryParams()['id'];
    $book = $booksTable->select(function (Select $select) use ($bookId) {
        $select
            ->columns(['title'])
            ->join(
                ['a' => 'author'],
                'b.author_id = a.author_id',
                ['author' => 'name']
            )
            ->where(['b.book_id' => $bookId])
        ;
    })->current();
    /** @var Twig_Environment $view */
    $view = require __DIR__ . '/../config/view.php';
    $response = new HtmlResponse($view->render('books/show.html.twig', [
        'book' => $book,
    ]));
} catch (Exception $e) {
    error_log("Exception: \n{$e}\n");
    $response = new HtmlResponse($view->render('errors/500.html.twig'), 500);
} finally {
    $emitter = new SapiEmitter();
    $emitter->emit($response);
}
