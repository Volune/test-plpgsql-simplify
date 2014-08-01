/*jshint mocha:true*/
var _ = require('underscore');
var pg = require('pg');
var fs = require('fs');
var path = require('path');
var expect = require('expect.js');

var pgConfig = {
    poolSize: 1,
    application_name: "test-plsql-simplify",
};
var ConnectionParameters = require("pg/lib/connection-parameters");
var pgUrl = process.env.PG_URL;
if (!pgUrl) {
    console.error('Run tests with environment variable PG_URL=postgres://user:pwd@hostname:post/db');
    process.exit(1);
}
console.log("Using %s", pgUrl);
_.extend(pgConfig, new ConnectionParameters(pgUrl));
_.extend(pg.defaults, pgConfig);

var testExpectGeometryDir = path.resolve(__dirname, 'expect_geometry');
var testExpectGeometrySql = '' + fs.readFileSync(path.resolve(__dirname, 'testExpectGeometry.sql'));
var testExpectNPointsDir = path.resolve(__dirname, 'expect_npoints');
var testExpectNPointsSql = '' + fs.readFileSync(path.resolve(__dirname, 'testExpectNPoints.sql'));

before(createSimplifyFunction);

describe('Test expect geometry', function () {
    var files = fs.readdirSync(testExpectGeometryDir);
    _.each(files, function (file) {
        it(file, function (done) {
            this.timeout(10000);
            testExpectGeometry(file, done);
        });
    });
});

describe('Test expect npoints', function () {
    var files = fs.readdirSync(testExpectNPointsDir);
    _.each(files, function (file) {
        it(file, function (done) {
            this.timeout(10000);
            testExpectNPoints(file, done);
        });
    });
});

function createSimplifyFunction(done) {
    var sql = '' + fs.readFileSync(path.resolve(__dirname, '../simplify.sql'));
    pg.connect(function (err, client, pgDone) {
        if (err) {
            done(err);
        } else {
            client.query(sql, function (err) {
                pgDone();
                done(err);
            });
        }
    });
}

function testExpectGeometry(directory, testDone) {
    var geometry = '' + fs.readFileSync(path.resolve(testExpectGeometryDir, directory, 'geometry.wkt'));
    var expected = '' + fs.readFileSync(path.resolve(testExpectGeometryDir, directory, 'expected.wkt'));
    pg.connect(function (err, client, pgDone) {
        if (err) {
            testDone(err);
        } else {
            client.query(testExpectGeometrySql, [geometry], function (err, result) {
                pgDone();
                if (err) {
                    testDone(err);
                } else {
                    expect(result).to.have.property('rows');
                    var rows = result.rows;
                    expect(rows).to.have.length(1);
                    expect(rows[0].geometry).to.equal(expected);
                    testDone();
                }
            });
        }
    });
}

function testExpectNPoints(file, testDone) {
    var geometry = '' + fs.readFileSync(path.resolve(testExpectNPointsDir, file));
    var match = file.match(/expect_(\d+)_point/);
    var expected = +match[1];
    pg.connect(function (err, client, pgDone) {
        if (err) {
            testDone(err);
        } else {
            client.query(testExpectNPointsSql, [geometry], function (err, result) {
                pgDone();
                if (err) {
                    testDone(err);
                } else {
                    expect(result).to.have.property('rows');
                    var rows = result.rows;
                    expect(rows).to.have.length(1);
                    expect(rows[0].points).to.equal(expected);
                    testDone();
                }
            });
        }
    });
}
