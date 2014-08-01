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

var dataDir = path.resolve(__dirname, 'data');
var testExpectGeometrySql = '' + fs.readFileSync(path.resolve(__dirname, 'testExpectGeometry.sql'));

describe('Test simplify polygons', function () {
    before(createSimplifyFunction);

    var files = fs.readdirSync(dataDir);
    _.each(files, function (file) {
        it(file, function (done) {
            this.timeout(10000);
            testExpectGeometry(file, done);
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
    var geometry = '' + fs.readFileSync(path.resolve(dataDir, directory, 'geometry.wkt'));
    var expected = '' + fs.readFileSync(path.resolve(dataDir, directory, 'expected.wkt'));
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
