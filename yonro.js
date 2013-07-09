// Generated by CoffeeScript 1.6.1
(function() {
  var $board, BLACK, BOARD_SIZE, EMPTY, EvaluationResult, MAX_SCORE, OnBoard, WHITE, adjacenciesAt, bgm, cancelWaiting, computerPlay, currentIndex, endGame, evalUntilDepth, evaluate, expected, openAndCloseModal, opponentOf, responseInterval, showOnBoard, userPlayAndResponse, userStone, waitForUserPlay;

  Array.prototype.isEqualTo = function(array) {
    if (this.length !== array.length) {
      return false;
    }
    return this.every(function(e, i) {
      return e === array[i];
    });
  };

  BOARD_SIZE = 4;

  MAX_SCORE = BOARD_SIZE * BOARD_SIZE - 2;

  EMPTY = 0;

  BLACK = 1;

  WHITE = 2;

  opponentOf = function(stone) {
    switch (stone) {
      case BLACK:
        return WHITE;
      case WHITE:
        return BLACK;
      default:
        throw 'error';
    }
  };

  adjacenciesAt = function(position) {
    var e, result, x, y, _i, _len, _ref;
    result = [];
    _ref = [[0, -1], [-1, 0], [1, 0], [0, 1]];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      e = _ref[_i];
      x = position[0] + e[0];
      y = position[1] + e[1];
      if ((0 <= x && x < BOARD_SIZE) && (0 <= y && y < BOARD_SIZE)) {
        result.push([x, y]);
      }
    }
    return result;
  };

  OnBoard = (function() {

    OnBoard.fromString = function(str) {
      var blacks, line, lines, whites, x, y, _i, _j, _len;
      blacks = [];
      whites = [];
      lines = str.replace(/(\r?\n)*$/, '').split(/\r?\n/);
      if (lines.length !== BOARD_SIZE) {
        throw 'bad format';
      }
      for (y = _i = 0, _len = lines.length; _i < _len; y = ++_i) {
        line = lines[y];
        if (line.length !== BOARD_SIZE) {
          throw 'bad format';
        }
        for (x = _j = 0; 0 <= BOARD_SIZE ? _j < BOARD_SIZE : _j > BOARD_SIZE; x = 0 <= BOARD_SIZE ? ++_j : --_j) {
          switch (line.charAt(x)) {
            case 'X':
              blacks.push([x, y]);
              break;
            case 'O':
              whites.push([x, y]);
              break;
            case ' ':
              null;
              break;
            default:
              throw 'bad format';
          }
        }
      }
      return new OnBoard(blacks, whites);
    };

    OnBoard.random = function() {
      var blacks, result, whites, x, y, _i, _j;
      while (true) {
        blacks = [];
        whites = [];
        for (x = _i = 0; 0 <= BOARD_SIZE ? _i < BOARD_SIZE : _i > BOARD_SIZE; x = 0 <= BOARD_SIZE ? ++_i : --_i) {
          for (y = _j = 0; 0 <= BOARD_SIZE ? _j < BOARD_SIZE : _j > BOARD_SIZE; y = 0 <= BOARD_SIZE ? ++_j : --_j) {
            switch (Math.floor(Math.random() * 3)) {
              case 1:
                blacks.push([x, y]);
                break;
              case 2:
                whites.push([x, y]);
            }
          }
        }
        result = new OnBoard(blacks, whites);
        if (result.isLegal()) {
          return result;
        }
      }
    };

    OnBoard.compare = function(a, b, stone) {
      var aBlack, aWhite, bBlack, bWhite, dame, eyes, index, numOfLiberties, score, strings, _ref, _ref1;
      score = a.score() - b.score();
      if (score !== 0) {
        if (stone === BLACK) {
          return score;
        } else {
          return -score;
        }
      }
      index = stone === BLACK ? 0 : 1;
      eyes = a.eyes()[index].length - b.eyes()[index].length;
      if (eyes !== 0) {
        return eyes;
      }
      _ref = a.strings(), aBlack = _ref[0], aWhite = _ref[1];
      _ref1 = b.strings(), bBlack = _ref1[0], bWhite = _ref1[1];
      numOfLiberties = function(strings) {
        return strings.reduce((function(sum, e) {
          return sum + e[1].length;
        }), 0);
      };
      switch (stone) {
        case BLACK:
          dame = (numOfLiberties(aBlack) - numOfLiberties(aWhite)) - (numOfLiberties(bBlack) - numOfLiberties(bWhite));
          if (dame !== 0) {
            return dame;
          }
          strings = bBlack.length - aBlack.length;
          if (strings !== 0) {
            return strings;
          }
          aBlack = a.stringsToContacts(aBlack);
          bBlack = b.stringsToContacts(bBlack);
          return bBlack.length - aBlack.length;
        case WHITE:
          dame = (numOfLiberties(aWhite) - numOfLiberties(aBlack)) - (numOfLiberties(bWhite) - numOfLiberties(bBlack));
          if (dame !== 0) {
            return dame;
          }
          strings = bWhite.length - aWhite.length;
          if (strings !== 0) {
            return strings;
          }
          aWhite = a.stringsToContacts(aWhite);
          bWhite = b.stringsToContacts(bWhite);
          return bWhite.length - aWhite.length;
      }
    };

    function OnBoard(blacks, whites) {
      var e, _i, _j, _len, _len1;
      this.onBoard = [[EMPTY, EMPTY, EMPTY, EMPTY], [EMPTY, EMPTY, EMPTY, EMPTY], [EMPTY, EMPTY, EMPTY, EMPTY], [EMPTY, EMPTY, EMPTY, EMPTY]];
      for (_i = 0, _len = blacks.length; _i < _len; _i++) {
        e = blacks[_i];
        this.onBoard[e[0]][e[1]] = BLACK;
      }
      for (_j = 0, _len1 = whites.length; _j < _len1; _j++) {
        e = whites[_j];
        this.onBoard[e[0]][e[1]] = WHITE;
      }
    }

    OnBoard.prototype.isEmptyAt = function(position) {
      switch (this.stateAt(position)) {
        case BLACK:
        case WHITE:
          return false;
        default:
          return true;
      }
    };

    OnBoard.prototype.isLegalAt = function(stone, position) {
      var board;
      board = this.copy();
      return board.place(stone, position);
    };

    OnBoard.prototype.isLegal = function() {
      var d, g, x, y, _i, _j, _ref;
      for (x = _i = 0; 0 <= BOARD_SIZE ? _i < BOARD_SIZE : _i > BOARD_SIZE; x = 0 <= BOARD_SIZE ? ++_i : --_i) {
        for (y = _j = 0; 0 <= BOARD_SIZE ? _j < BOARD_SIZE : _j > BOARD_SIZE; y = 0 <= BOARD_SIZE ? ++_j : --_j) {
          if (!(!this.isEmptyAt([x, y]))) {
            continue;
          }
          _ref = this.stringAndLibertyAt([x, y]), g = _ref[0], d = _ref[1];
          if (d.length === 0) {
            return false;
          }
        }
      }
      return true;
    };

    OnBoard.prototype.isEqualTo = function(board) {
      /*
      for x in [0...BOARD_SIZE]
          for y in [0...BOARD_SIZE]
              return false if @stateAt([x, y]) isnt board.stateAt([x, y])
      true
      */
      return this.onBoard.every(function(column, i) {
        return column.isEqualTo(board.onBoard[i]);
      });
    };

    OnBoard.prototype.stateAt = function(position) {
      return this.onBoard[position[0]][position[1]];
    };

    OnBoard.prototype.deployment = function() {
      var blacks, position, whites, x, y, _i, _j;
      blacks = [];
      whites = [];
      for (x = _i = 0; 0 <= BOARD_SIZE ? _i < BOARD_SIZE : _i > BOARD_SIZE; x = 0 <= BOARD_SIZE ? ++_i : --_i) {
        for (y = _j = 0; 0 <= BOARD_SIZE ? _j < BOARD_SIZE : _j > BOARD_SIZE; y = 0 <= BOARD_SIZE ? ++_j : --_j) {
          position = [x, y];
          switch (this.stateAt(position)) {
            case BLACK:
              blacks.push(position);
              break;
            case WHITE:
              whites.push(position);
          }
        }
      }
      return [blacks, whites];
    };

    OnBoard.prototype.score = function() {
      var blacks, whites, _ref;
      _ref = this.deployment(), blacks = _ref[0], whites = _ref[1];
      return blacks.length - whites.length;
    };

    OnBoard.prototype.add = function(stone, position) {
      return this.onBoard[position[0]][position[1]] = stone;
    };

    OnBoard.prototype["delete"] = function(position) {
      return this.add(EMPTY, position);
    };

    OnBoard.prototype.candidates = function(stone) {
      var position, result, x, y, _i, _j;
      result = [];
      for (x = _i = 0; 0 <= BOARD_SIZE ? _i < BOARD_SIZE : _i > BOARD_SIZE; x = 0 <= BOARD_SIZE ? ++_i : --_i) {
        for (y = _j = 0; 0 <= BOARD_SIZE ? _j < BOARD_SIZE : _j > BOARD_SIZE; y = 0 <= BOARD_SIZE ? ++_j : --_j) {
          position = [x, y];
          if (this.isLegalAt(stone, position) && !(this.whoseEyeAt(position) === stone)) {
            result.push(position);
          }
        }
      }
      return result;
    };

    OnBoard.prototype.stringAndLibertyAt = function(position) {
      var aux, stone,
        _this = this;
      if (this.isEmptyAt(position)) {
        return null;
      }
      stone = this.stateAt(position);
      aux = function(unchecked, string, liberty) {
        var adjacencies, adjacency, checking, _i, _len;
        if (unchecked.length === 0) {
          return [string, liberty];
        }
        checking = unchecked.pop();
        adjacencies = adjacenciesAt(checking);
        for (_i = 0, _len = adjacencies.length; _i < _len; _i++) {
          adjacency = adjacencies[_i];
          if ((_this.stateAt(adjacency) === stone) && (string.every(function(e) {
            return !e.isEqualTo(adjacency);
          }))) {
            string.push(adjacency);
            unchecked.push(adjacency);
          } else if (_this.isEmptyAt(adjacency) && (liberty.every(function(e) {
            return !e.isEqualTo(adjacency);
          }))) {
            liberty.push(adjacency);
          }
        }
        return aux(unchecked, string, liberty);
      };
      return aux([position], [position], []);
    };

    OnBoard.prototype.emptyStringAt = function(position) {
      var aux,
        _this = this;
      if (!this.isEmptyAt(position)) {
        return null;
      }
      aux = function(unchecked, string) {
        var adjacencies, adjacency, checking, _i, _len;
        if (unchecked.length === 0) {
          return string;
        }
        checking = unchecked.pop();
        adjacencies = adjacenciesAt(checking);
        for (_i = 0, _len = adjacencies.length; _i < _len; _i++) {
          adjacency = adjacencies[_i];
          if (_this.isEmptyAt(adjacency) && (string.every(function(e) {
            return !e.isEqualTo(adjacency);
          }))) {
            string.push(adjacency);
            unchecked.push(adjacency);
          }
        }
        return aux(unchecked, string);
      };
      return aux([position], [position]);
    };

    OnBoard.prototype.emptyStrings = function() {
      var position, result, x, y, _i, _j;
      result = [];
      for (x = _i = 0; 0 <= BOARD_SIZE ? _i < BOARD_SIZE : _i > BOARD_SIZE; x = 0 <= BOARD_SIZE ? ++_i : --_i) {
        for (y = _j = 0; 0 <= BOARD_SIZE ? _j < BOARD_SIZE : _j > BOARD_SIZE; y = 0 <= BOARD_SIZE ? ++_j : --_j) {
          position = [x, y];
          if ((this.isEmptyAt(position)) && (result.every(function(s) {
            return s.every(function(e) {
              return !e.isEqualTo(position);
            });
          }))) {
            result.push(this.emptyStringAt(position));
          }
        }
      }
      return result;
    };

    OnBoard.prototype.strings = function() {
      var position, result, x, y, _i, _j;
      result = [[], []];
      for (x = _i = 0; 0 <= BOARD_SIZE ? _i < BOARD_SIZE : _i > BOARD_SIZE; x = 0 <= BOARD_SIZE ? ++_i : --_i) {
        for (y = _j = 0; 0 <= BOARD_SIZE ? _j < BOARD_SIZE : _j > BOARD_SIZE; y = 0 <= BOARD_SIZE ? ++_j : --_j) {
          position = [x, y];
          switch (this.stateAt(position)) {
            case BLACK:
              if (result[0].every(function(g) {
                return g.every(function(e) {
                  return !e[0].isEqualTo(position);
                });
              })) {
                result[0].push(this.stringAndLibertyAt(position));
              }
              break;
            case WHITE:
              if (result[1].every(function(g) {
                return g.every(function(e) {
                  return !e[0].isEqualTo(position);
                });
              })) {
                result[1].push(this.stringAndLibertyAt(position));
              }
          }
        }
      }
      return result;
    };

    OnBoard.prototype.isTouchedBetween = function(a, b) {
      var p, q, _i, _j, _len, _len1;
      for (_i = 0, _len = a.length; _i < _len; _i++) {
        p = a[_i];
        for (_j = 0, _len1 = b.length; _j < _len1; _j++) {
          q = b[_j];
          if ((Math.abs(p[0] - q[0]) === 1) && (Math.abs(p[1] - q[1]) === 1)) {
            return true;
          }
        }
      }
      return false;
    };

    OnBoard.prototype.stringsToContacts = function(strings) {
      var i, j, result, unique, _i, _j, _ref, _ref1, _ref2, _ref3;
      result = [];
      for (i = _i = 0, _ref = strings.length; 0 <= _ref ? _i < _ref : _i > _ref; i = 0 <= _ref ? ++_i : --_i) {
        if ((_ref1 = result[i]) == null) {
          result[i] = [strings[i]];
        }
        for (j = _j = _ref2 = i + 1, _ref3 = strings.length; _ref2 <= _ref3 ? _j < _ref3 : _j > _ref3; j = _ref2 <= _ref3 ? ++_j : --_j) {
          if (this.isTouchedBetween(strings[i][0], strings[j][0])) {
            result[i].push(strings[j]);
            result[j] = result[i];
          }
        }
      }
      unique = function(array) {
        var e, _k, _len;
        result = [];
        for (_k = 0, _len = array.length; _k < _len; _k++) {
          e = array[_k];
          if (result.indexOf(e) < 0) {
            result.push(e);
          }
        }
        return result;
      };
      return unique(result);
    };

    OnBoard.prototype.whoseEyeAt = function(position, checkings) {
      var adjacencies, gd0, gds, gds0, stone, _i, _len,
        _this = this;
      if (checkings == null) {
        checkings = [];
      }
      if (!this.isEmptyAt(position)) {
        return null;
      }
      adjacencies = adjacenciesAt(position);
      if (!(adjacencies.every(function(e) {
        return _this.stateAt(e) === BLACK;
      }) || adjacencies.every(function(e) {
        return _this.stateAt(e) === WHITE;
      }))) {
        return null;
      }
      stone = this.stateAt(adjacencies[0]);
      gds0 = adjacencies.map(function(e) {
        var a;
        return a = _this.stringAndLibertyAt(e);
      });
      gds = [];
      for (_i = 0, _len = gds0.length; _i < _len; _i++) {
        gd0 = gds0[_i];
        if (gds.length === 0 || !(gds.some(function(gd) {
          return gd[0].some(function(e) {
            return e.isEqualTo(gd0[0][0]);
          });
        }))) {
          gds.push(gd0);
        }
      }
      if (gds.length === 1 || (gds.every(function(gd) {
        var newCheckings;
        newCheckings = checkings.concat([position]);
        return gd[1].filter(function(e) {
          return !e.isEqualTo(position);
        }).some(function(d) {
          return checkings.some(function(e) {
            return d.isEqualTo(e);
          }) || (function(c) {
            return _this.whoseEyeAt(d, c) === stone;
          })(newCheckings);
        });
      }))) {
        return stone;
      } else {
        return null;
      }
    };

    OnBoard.prototype.eyes = function() {
      var result, x, y, _i, _j;
      result = [[], []];
      for (x = _i = 0; 0 <= BOARD_SIZE ? _i < BOARD_SIZE : _i > BOARD_SIZE; x = 0 <= BOARD_SIZE ? ++_i : --_i) {
        for (y = _j = 0; 0 <= BOARD_SIZE ? _j < BOARD_SIZE : _j > BOARD_SIZE; y = 0 <= BOARD_SIZE ? ++_j : --_j) {
          switch (this.whoseEyeAt([x, y])) {
            case BLACK:
              result[0].push([x, y]);
              break;
            case WHITE:
              result[1].push([x, y]);
          }
        }
      }
      return result;
    };

    OnBoard.prototype.copy = function() {
      var blacks, whites, _ref;
      _ref = this.deployment(), blacks = _ref[0], whites = _ref[1];
      return new OnBoard(blacks, whites);
    };

    OnBoard.prototype.captureBy = function(position) {
      var adjacencies, adjacency, captives, capturedStone, e, stringAndLiberty, _i, _j, _len, _len1, _ref;
      capturedStone = opponentOf(this.stateAt(position));
      adjacencies = adjacenciesAt(position);
      captives = [];
      for (_i = 0, _len = adjacencies.length; _i < _len; _i++) {
        adjacency = adjacencies[_i];
        if (!(this.stateAt(adjacency) === capturedStone)) {
          continue;
        }
        stringAndLiberty = this.stringAndLibertyAt(adjacency);
        if (stringAndLiberty[1].length === 0) {
          _ref = stringAndLiberty[0];
          for (_j = 0, _len1 = _ref.length; _j < _len1; _j++) {
            e = _ref[_j];
            this["delete"](e);
          }
          captives = captives.concat(stringAndLiberty[0]);
        }
      }
      return captives;
    };

    OnBoard.prototype.place = function(stone, position) {
      var adjacencies, liberty, string, _ref;
      if (position == null) {
        return true;
      }
      if (!this.isEmptyAt(position)) {
        return false;
      }
      adjacencies = adjacenciesAt(position);
      this.add(stone, position);
      this.captureBy(position);
      _ref = this.stringAndLibertyAt(position), string = _ref[0], liberty = _ref[1];
      if (liberty.length === 0) {
        this["delete"](position);
        return false;
      }
      return true;
    };

    OnBoard.prototype.toString = function() {
      var str, x, y, _i, _j;
      str = new String();
      for (y = _i = 0; 0 <= BOARD_SIZE ? _i < BOARD_SIZE : _i > BOARD_SIZE; y = 0 <= BOARD_SIZE ? ++_i : --_i) {
        for (x = _j = 0; 0 <= BOARD_SIZE ? _j < BOARD_SIZE : _j > BOARD_SIZE; x = 0 <= BOARD_SIZE ? ++_j : --_j) {
          str += (function() {
            switch (this.onBoard[x][y]) {
              case BLACK:
                return 'X';
              case WHITE:
                return 'O';
              default:
                return ' ';
            }
          }).call(this);
        }
        str += '\n';
      }
      return str;
    };

    return OnBoard;

  })();

  evaluate = function(history, next) {
    return evalUntilDepth(history, next, 100);
    /*
    for depth in [18, 34]
        result = evalUntilDepth board, next, 0, depth, history
        return result unless isNaN result
    NaN
    */

  };

  EvaluationResult = (function() {

    function EvaluationResult(value, history) {
      this.value = value;
      this.history = history;
    }

    return EvaluationResult;

  })();

  evalUntilDepth = function(history, next, depth, alpha, beta) {
    var alpha0, b, beta0, board, candidates, nodes, opponent, p, parity, result, _i, _j, _k, _len, _len1, _len2;
    if (alpha == null) {
      alpha = {
        value: -Infinity,
        history: null
      };
    }
    if (beta == null) {
      beta = {
        value: Infinity,
        history: null
      };
    }
    board = history[history.length - 1];
    if ((board === history[history.length - 2]) && (board === history[history.length - 3])) {
      return new EvaluationResult(board.score(), history);
    }
    if (depth === 0) {
      return new EvaluationResult(NaN, history);
    }
    opponent = opponentOf(next);
    candidates = board.candidates(next);
    nodes = [];
    for (_i = 0, _len = candidates.length; _i < _len; _i++) {
      p = candidates[_i];
      b = board.copy();
      b.place(next, p);
      parity = history.length % 2;
      if (history.filter(function(e, i) {
        return (i % 2) === parity;
      }).every(function(e) {
        return !b.isEqualTo(e);
      })) {
        nodes.push(b);
      }
    }
    switch (next) {
      case BLACK:
        nodes.sort(function(a, b) {
          return -OnBoard.compare(a, b, next);
        });
        alpha0 = alpha;
        for (_j = 0, _len1 = nodes.length; _j < _len1; _j++) {
          b = nodes[_j];
          if ((b.deployment()[1].length <= 1) && (b.emptyStrings().length >= 2)) {
            alpha = new EvaluationResult(MAX_SCORE, history.concat(b));
            return alpha;
          } else {
            result = null;
            if (result == null) {
              result = evalUntilDepth(history.concat(b), opponent, depth - 1, alpha, beta);
            }
            if (result.value === MAX_SCORE) {
              return result;
            }
            alpha = (isNaN(alpha.value)) || (alpha.value >= result.value) ? alpha : result;
            if (alpha.value >= beta.value) {
              return beta;
            }
          }
        }
        result = evalUntilDepth(history.concat(board), opponent, depth - 1, alpha, beta);
        if (result.value === MAX_SCORE) {
          return result;
        }
        alpha = (isNaN(alpha.value)) || (alpha.value >= result.value) ? alpha : result;
        if (alpha.value >= beta.value) {
          return beta;
        }
        return alpha;
      case WHITE:
        nodes.sort(function(a, b) {
          return -OnBoard.compare(a, b, next);
        });
        beta0 = beta;
        for (_k = 0, _len2 = nodes.length; _k < _len2; _k++) {
          b = nodes[_k];
          if ((b.deployment()[0].length <= 1) && (b.emptyStrings().length >= 2)) {
            beta = new EvaluationResult(-MAX_SCORE, history.concat(b));
            return beta;
          } else {
            result = null;
            if (result == null) {
              result = evalUntilDepth(history.concat(b), opponent, depth - 1, alpha, beta);
            }
            if (result.value === -MAX_SCORE) {
              return result;
            }
            beta = (isNaN(beta.value)) || (beta.value <= result.value) ? beta : result;
            if (alpha.value >= beta.value) {
              return alpha;
            }
          }
        }
        result = evalUntilDepth(history.concat(board), opponent, depth - 1, alpha, beta);
        if (result.value === -MAX_SCORE) {
          return result;
        }
        beta = (isNaN(beta.value)) || (beta.value <= result.value) ? beta : result;
        if (alpha.value >= beta.value) {
          return alpha;
        }
        return beta;
    }
  };

  /*
  # 四路の碁(仮名)
  # (C) 2013 ICHIKAWA, Yuji (New 3 Rs)
  */


  userStone = BLACK;

  expected = null;

  currentIndex = 0;

  responseInterval = 2000;

  window.printExpected = function() {
    console.log(expected.history.map(function(e) {
      return e.toString();
    }).join('\n'));
    return console.log(expected.value);
  };

  bgm = {
    element: $('#bgm')[0],
    state: 'stop',
    play: function() {
      bgm.element.play();
      return bgm.state = 'play';
    },
    pause: function() {
      bgm.element.pause();
      return bgm.state = 'pause';
    },
    stop: function() {
      bgm.element.pause();
      bgm.state = 'stop';
      try {
        return bgm.element.currentTime = 0;
      } catch (e) {
        return console.log(e);
      }
    }
  };

  window.onpagehide = function() {
    if (bgm.state === 'play') {
      return bgm.pause();
    }
  };

  window.onpageshow = function() {
    if (bgm.state === 'pause') {
      return bgm.play();
    }
  };

  evaluate = function(history, next, success, error, timeout) {
    var timeid, worker;
    if (timeout == null) {
      timeout = 10000;
    }
    $('#evaluating').css('display', 'inline');
    timeid = null;
    worker = new Worker('go-worker.js');
    worker.onmessage = function(event) {
      $('#evaluating').css('display', 'none');
      clearTimeout(timeid);
      if (event.data.error != null) {
        return error(event.data.error);
      } else {
        return success({
          value: event.data.value,
          history: event.data.history.map(function(e) {
            return OnBoard.fromString(e);
          })
        });
      }
    };
    worker.postMessage({
      history: history.map(function(e) {
        return e.toString();
      }),
      next: next
    });
    return timeid = setTimeout((function() {
      $('#evaluating').css('display', 'none');
      worker.terminate();
      return error({
        message: 'timeout'
      });
    }), timeout);
  };

  showOnBoard = function(board, effect, callback) {
    var $intersection, blacks, deferred, deferredes, p, place, whites, x, y, _i, _j, _ref;
    if (effect == null) {
      effect = false;
    }
    if (board == null) {
      $('.intersection').removeClass('black white half-opacity');
      return;
    }
    _ref = board.deployment(), blacks = _ref[0], whites = _ref[1];
    deferredes = [];
    for (x = _i = 0; 0 <= BOARD_SIZE ? _i < BOARD_SIZE : _i > BOARD_SIZE; x = 0 <= BOARD_SIZE ? ++_i : --_i) {
      for (y = _j = 0; 0 <= BOARD_SIZE ? _j < BOARD_SIZE : _j > BOARD_SIZE; y = 0 <= BOARD_SIZE ? ++_j : --_j) {
        p = [x, y];
        $intersection = $(".intersection:nth-child(" + (1 + p[0] + p[1] * BOARD_SIZE) + ")");
        place = function(blackOrWhite) {
          var deferred;
          if (effect && ((!$intersection.hasClass(blackOrWhite)) || ($intersection.hasClass('half-opacity')))) {
            deferred = $.Deferred();
            deferredes.push(deferred);
            $intersection.one($s.vendor.animationend, function() {
              $(this).removeClass('shake');
              return deferred.resolve();
            });
            return $intersection.removeClass('half-opacity').addClass("" + blackOrWhite + " shake");
          } else {
            return $intersection.removeClass('white half-opacity').addClass(blackOrWhite);
          }
        };
        if (blacks.some(function(e) {
          return e.isEqualTo(p);
        })) {
          place('black');
        } else if (whites.some(function(e) {
          return e.isEqualTo(p);
        })) {
          place('white');
        } else {
          if (effect && ($intersection.hasClass('black') || ($intersection.hasClass('white')))) {
            deferred = $.Deferred();
            deferredes.push(deferred);
            $intersection.one($s.vendor.transitionend, (function(deferred) {
              return function() {
                $(this).removeClass('black white rise');
                return deferred.resolve();
              };
            })(deferred));
            $intersection.addClass('rise');
          } else {
            $intersection.removeClass('white black half-opacity');
          }
        }
      }
    }
    console.log(deferredes);
    if (effect) {
      return $.when.apply(window, deferredes).done(callback);
    }
  };

  endGame = function() {
    var score;
    bgm.stop();
    score = expected.value - expected.history[0].score();
    alert(score === 0 ? '引き分け' : score > 0 ? "黒" + score + "目勝ち" : "白" + (-score) + "目勝ち");
    return $('#start-stop').removeAttr('disabled');
  };

  openAndCloseModal = function(id, callback) {
    $("#" + id).modal('show');
    return setTimeout((function() {
      $("#" + id).modal('hide');
      return callback();
    }), responseInterval);
  };

  computerPlay = function(board) {
    var behaveNext, score, _ref, _ref1;
    behaveNext = function() {
      currentIndex += 1;
      if (currentIndex < expected.history.length) {
        if (board.isEqualTo(expected.history[currentIndex])) {
          return setTimeout((function() {
            var _ref, _ref1;
            alert('パスします');
            if (((_ref = expected.history[currentIndex - 2]) != null ? _ref.isEqualTo(board) : void 0) && ((_ref1 = expected.history[currentIndex - 1]) != null ? _ref1.isEqualTo(board) : void 0)) {
              return endGame();
            } else {
              return waitForUserPlay();
            }
          }), 0);
        } else {
          return showOnBoard(expected.history[currentIndex], true, waitForUserPlay);
        }
      } else {
        return endGame();
      }
    };
    if ((_ref = expected.history[currentIndex]) != null ? _ref.isEqualTo(board) : void 0) {
      if (expected.history.length - 1 > currentIndex) {
        if (!((_ref1 = expected.history[currentIndex - 1]) != null ? _ref1.isEqualTo(board) : void 0)) {
          score = expected.value - expected.history[0].score();
          score = userStone === BLACK ? -score : score;
          if (score > 0) {
            return openAndCloseModal('expect-modal', behaveNext);
          } else if ((userStone === BLACK ? -expected.value : expected.value) === -MAX_SCORE) {
            return openAndCloseModal('pessimistic-modal', behaveNext);
          } else {
            return setTimeout((function() {
              return behaveNext();
            }), responseInterval);
          }
        } else {
          return setTimeout((function() {
            return behaveNext();
          }), responseInterval);
        }
      } else if (expected.value === (userStone === BLACK ? MAX_SCORE : -MAX_SCORE)) {
        bgm.stop();
        return setTimeout((function() {
          alert('負けました…');
          return $('#start-stop').removeAttr('disabled');
        }), responseInterval);
      } else {
        $('#unexpected-modal').modal('show');
        return evaluate(expected.history.slice(0, currentIndex).concat(board), opponentOf(userStone), (function(result) {
          expected = result;
          return behaveNext();
        }), (function(error) {
          var b, candidates, computerStone, nodes, p, parity, _i, _len;
          $('#evaluate-modal').modal('hide');
          expected = {
            value: NaN,
            history: expected.history.slice(0, currentIndex).concat(board)
          };
          computerStone = opponentOf(userStone);
          candidates = board.candidates(computerStone);
          nodes = [];
          for (_i = 0, _len = candidates.length; _i < _len; _i++) {
            p = candidates[_i];
            b = board.copy();
            b.place(computerStone, p);
            parity = userStone === BLACK ? 0 : 1;
            if (expected.history.filter(function(e, i) {
              return (i % 2) === parity;
            }).every(function(e) {
              return !b.isEqualTo(e);
            })) {
              nodes.push(b);
            }
          }
          nodes.sort(function(a, b) {
            return -OnBoard.compare(a, b, computerStone);
          });
          expected.history.push(nodes[0]);
          return openAndCloseModal('upset-modal', behaveNext);
        }));
      }
    } else {
      return evaluate(expected.history.slice(0, currentIndex).concat(board), opponentOf(userStone), (function(result) {
        expected = result;
        return behaveNext();
      }), (function(error) {
        var b, candidates, computerStone, nodes, p, parity, _i, _len;
        expected = {
          value: NaN,
          history: expected.history.slice(0, currentIndex).concat(board)
        };
        computerStone = opponentOf(userStone);
        candidates = board.candidates(computerStone);
        nodes = [];
        for (_i = 0, _len = candidates.length; _i < _len; _i++) {
          p = candidates[_i];
          b = board.copy();
          b.place(computerStone, p);
          parity = userStone === BLACK ? 0 : 1;
          if (expected.history.filter(function(e, i) {
            return (i % 2) === parity;
          }).every(function(e) {
            return !b.isEqualTo(e);
          })) {
            nodes.push(b);
          }
        }
        nodes.sort(function(a, b) {
          return -OnBoard.compare(a, b, computerStone);
        });
        expected.history.push(nodes[0]);
        return behaveNext();
      }));
    }
  };

  userPlayAndResponse = function(position) {
    var board, parity;
    $('#pass, #resign').attr('disabled', 'disabled');
    board = expected.history[currentIndex].copy();
    if (board.place(userStone, position)) {
      parity = (currentIndex + 1) % 2;
      if ((position != null) && expected.history.slice(0, currentIndex).filter(function(e, i) {
        return (i % 2) === parity;
      }).some(function(e) {
        return board.isEqualTo(e);
      })) {
        alert('そこへ打つと繰り返し…');
        showOnBoard(expected.history[currentIndex]);
        return waitForUserPlay();
      } else {
        return showOnBoard(board, true, function() {
          currentIndex += 1;
          return computerPlay(board);
        });
      }
    } else {
      alert('そこは打てないよ〜');
      showOnBoard(expected.history[currentIndex]);
      return waitForUserPlay();
    }
  };

  $board = $('#board');

  if (window.Touch) {
    waitForUserPlay = function() {
      $board.on('touchstart', '.intersection:not(.black):not(.white)', function() {
        $board.off('touchstart', '.intersection:not(.black):not(.white)');
        $(this).addClass("" + (userStone === BLACK ? 'black' : 'white') + " half-opacity");
        $board.on('touchmove', function(e) {
          var $target, event;
          event = e.originalEvent;
          $target = $(document.elementFromPoint(event.touches[0].clientX, event.touches[0].clientY));
          if ($target.is('.intersection:not(.black):not(.white)')) {
            $target.parent().children('.half-opacity').removeClass('black white half-opacity');
            return $target.addClass("" + (userStone === BLACK ? 'black' : 'white') + " half-opacity");
          }
        });
        return $board.on('touchend touchcancel', function(e) {
          var $target, event, index;
          $board.off('touchmove touchend touchcancel');
          if (e.type === 'touchcancel') {
            return;
          }
          event = e.originalEvent;
          $target = $(document.elementFromPoint(event.changedTouches[0].clientX, event.changedTouches[0].clientY));
          if ($target.is('.intersection.half-opacity')) {
            index = $target.prevAll().length;
            return userPlayAndResponse.call(this, [index % BOARD_SIZE, Math.floor(index / BOARD_SIZE)]);
          }
        });
      });
      return $('#pass, #resign').removeAttr('disabled');
    };
    cancelWaiting = function() {
      $board.off('touchstart', '.intersection:not(.black):not(.white)');
      return $board.off('touchmove touchend touchcancel');
    };
  } else {
    waitForUserPlay = function() {
      $board.on('mousedown', '.intersection:not(.black):not(.white)', function() {
        $board.off('mousedown', '.intersection:not(.black):not(.white)');
        $(this).addClass("" + (userStone === BLACK ? 'black' : 'white') + " half-opacity");
        $board.on('mouseleave', '.intersection.half-opacity', function() {
          return $(this).removeClass('black white half-opacity');
        });
        $board.on('mouseenter', '.intersection:not(.black):not(.white)', function() {
          return $(this).addClass("" + (userStone === BLACK ? 'black' : 'white') + " half-opacity");
        });
        return $board.on('mouseup', '.intersection.half-opacity', function() {
          var index;
          $board.off('mouseleave', '.intersection.half-opacity');
          $board.off('mouseenter', '.intersection:not(.black):not(.white)');
          $board.off('mouseup', '.intersection.half-opacity');
          index = $(this).prevAll().length;
          return userPlayAndResponse.call(this, [index % BOARD_SIZE, Math.floor(index / BOARD_SIZE)]);
        });
      });
      return $('#pass, #resign').removeAttr('disabled');
    };
    cancelWaiting = function() {
      $board.off('mousedown', '.intersection:not(.black):not(.white)');
      $board.off('mouseleave', '.intersection.half-opacity');
      $board.off('mouseenter', '.intersection:not(.black):not(.white)');
      return $board.off('mouseup', '.intersection.half-opacity');
    };
  }

  $(document.body).on('touchmove', function(e) {
    if (window.Touch) {
      return e.preventDefault();
    }
  });

  $('#start-stop').on('click', function() {
    var board;
    console.log('click');
    showOnBoard(null);
    board = OnBoard.fromString('XO X\n XOX\n OXO\nO X ');
    expected = {
      value: NaN,
      history: [board]
    };
    currentIndex = 0;
    showOnBoard(expected.history[currentIndex]);
    return $('#select-modal').modal('show');
  });

  $('#play-white, #play-black').on('click', function() {
    $('#start-stop').attr('disabled', 'disabled');
    userStone = (function() {
      switch (this.id) {
        case 'play-white':
          return WHITE;
        case 'play-black':
          return BLACK;
        default:
          return null;
      }
    }).call(this);
    bgm.play();
    return openAndCloseModal('start-modal', function() {
      if (userStone === BLACK) {
        return waitForUserPlay();
      } else {
        return computerPlay(expected.history[currentIndex]);
      }
    });
  });

  $('#pass').on('click', function() {
    cancelWaiting();
    return userPlayAndResponse(null);
  });

  $('#resign').on('click', function() {
    cancelWaiting();
    bgm.stop();
    return openAndCloseModal('end-modal', function() {
      $('#start-stop').removeAttr('disabled');
      return $('#pass, #resign').attr('disabled', 'disabled');
    });
  });

}).call(this);
