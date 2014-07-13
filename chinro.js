// Generated by CoffeeScript 1.7.1

/*
碁カーネル
中国ルールを採用。ただし自殺手は着手禁止とする。
 */

(function() {
  var BLACK, BOARD_SIZE, EMPTY, EvaluationResult, MAX_SCORE, OnBoard, WHITE, adjacenciesAt, boardOnScreen, cancelMessage, chase, chaseShicho, chaser, checkTarget, compare, editBoard, escape, escaper, evaluatedResult, longestFail, longestSuccess, openAndCloseModal, opponentOf, playSequence, responseInterval, scheduleMessage, setBoardSize, showOnBoard, startSolve, stopEditing, target, wEvaluate;

  Array.prototype.isEqualTo = function(array) {

    /*　配列の要素すべてが等しいか否かを返す。 */
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

  setBoardSize = function(size) {

    /* 碁盤のサイズを設定する。 デフォルトは4路。 */
    BOARD_SIZE = size;
    return MAX_SCORE = size * size - 2;
  };

  opponentOf = function(stone) {

    /* 黒(BLACK)なら白(WHITE)、白(WHITE)なら黒(BLACK)を返す。 */
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

    /* プライベート */

    /* 隣接する点の座標の配列を返す。 */
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

  compare = function(a, b, stone) {

    /*
    探索のための優先順位を決める局面比較関数。
    a, bは比較する局面。stoneの立場で比較し、結果を整数値で返す。
    
    1. スコアに差があればそれを返す。(石を取った手を優先する)
    2. 自分の眼の数に差があればそれを返す。(眼形が多い手を優先する)
    3. 自分のダメの数と相手のダメの数の差に差があればそれを返す。(攻め合いに有効な手を優先する)
    4. 自分の連(string)の数に差があればそれにマイナスを掛けた値を返す。(つながる手を優先する)
    5. 自分のつながり(contact)の数に差があればそれにマイナスを掛けた値を返す。(つながる手を優先する)
     */
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

  OnBoard = (function() {

    /* 盤上の状態を表すクラス */
    OnBoard.fromString = function(str) {

      /* 盤上の状態を表すX(黒)とO(白)と空点(スペース)と改行で文字列からインスタンスを生成する。 */
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

      /* ランダムな配置の碁盤を返す。 */
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

    function OnBoard(blacks, whites) {

      /* blacks, whitesは黒石/白石のある場所の座標の配列。 */
      var e, i, j, _i, _j, _k, _l, _len, _len1, _ref, _ref1;
      this.onBoard = new Array(BOARD_SIZE);
      for (i = _i = 0, _ref = this.onBoard.length; 0 <= _ref ? _i < _ref : _i > _ref; i = 0 <= _ref ? ++_i : --_i) {
        this.onBoard[i] = new Array(BOARD_SIZE);
        for (j = _j = 0, _ref1 = this.onBoard[i].length; 0 <= _ref1 ? _j < _ref1 : _j > _ref1; j = 0 <= _ref1 ? ++_j : --_j) {
          this.onBoard[i][j] = EMPTY;
        }
      }
      for (_k = 0, _len = blacks.length; _k < _len; _k++) {
        e = blacks[_k];
        this.onBoard[e[0]][e[1]] = BLACK;
      }
      for (_l = 0, _len1 = whites.length; _l < _len1; _l++) {
        e = whites[_l];
        this.onBoard[e[0]][e[1]] = WHITE;
      }
    }

    OnBoard.prototype.isEmptyAt = function(position) {

      /* 座標が空点かどうか。 */
      switch (this.stateAt(position)) {
        case BLACK:
        case WHITE:
          return false;
        default:
          return true;
      }
    };

    OnBoard.prototype.isLegalAt = function(stone, position) {

      /*
      座標が合法着手点かどうか。
      コウ(循環)の着手禁止はチェックしない。循環については手順関連で別途チェックすること
       */
      var board;
      board = this.copy();
      return board.place(stone, position);
    };

    OnBoard.prototype.isLegal = function() {

      /* 盤上の状態が合法がどうか。(ダメ詰まりの石が存在しないこと) */
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

      /* 盤上が同じかどうか。 */

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

      /* 座標の状態を返す。 */
      return this.onBoard[position[0]][position[1]];
    };

    OnBoard.prototype.deployment = function() {

      /*
      現在の配置を返す。
      コンストラクタの逆関数
       */
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

      /*
      石の数の差を返す。
      中国ルールを採用。盤上の石の数の差が評価値。
       */
      var blacks, whites, _ref;
      _ref = this.deployment(), blacks = _ref[0], whites = _ref[1];
      return blacks.length - whites.length;
    };

    OnBoard.prototype.add = function(stone, position) {

      /*
      石を座標にセットする。
      stateはBLACK, WHITEのいずれか。(本当はEMPTYもOK)
       */
      return this.onBoard[position[0]][position[1]] = stone;
    };

    OnBoard.prototype["delete"] = function(position) {

      /* 座標の石をただ取る。 */
      return this.add(EMPTY, position);
    };

    OnBoard.prototype.candidates = function(stone) {

      /* stoneの手番で、合法かつ自分の眼ではない座標すべての配列を返す。 */
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

      /*
      座標の石と接続した同一石の座標の配列とその石の集合のダメの座標の配列を返す。
      接続した石の集団を連(ストリング)と呼ぶ。
       */
      var aux, stone;
      if (this.isEmptyAt(position)) {
        return null;
      }
      stone = this.stateAt(position);
      aux = (function(_this) {
        return function(unchecked, string, liberty) {
          var adjacencies, adjacency, checking, equalPositions, _i, _len;
          if (unchecked.length === 0) {
            return [string, liberty];
          }
          checking = unchecked.pop();
          adjacencies = adjacenciesAt(checking);
          equalPositions = function(a, b) {
            return (a[0] === b[0]) && (a[1] === b[1]);
          };
          for (_i = 0, _len = adjacencies.length; _i < _len; _i++) {
            adjacency = adjacencies[_i];
            if ((_this.stateAt(adjacency) === stone) && (string.every(function(e) {
              return !equalPositions(e, adjacency);
            }))) {
              string.push(adjacency);
              unchecked.push(adjacency);
            } else if (_this.isEmptyAt(adjacency) && (liberty.every(function(e) {
              return !equalPositions(e, adjacency);
            }))) {
              liberty.push(adjacency);
            }
          }
          return aux(unchecked, string, liberty);
        };
      })(this);
      return aux([position], [position], []);
    };

    OnBoard.prototype.emptyStringAt = function(position) {

      /* 座標の空点と接続した空点の座標の配列を返す。 */
      var aux;
      if (!this.isEmptyAt(position)) {
        return null;
      }
      aux = (function(_this) {
        return function(unchecked, string) {
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
      })(this);
      return aux([position], [position]);
    };

    OnBoard.prototype.emptyStrings = function() {

      /* 盤上の空点のストリングを返す。 */
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

      /* 盤上のストリングを返す。1つ目の要素が黒のストリング、2つ目の要素が白のストリング。 */
      var position, result, x, y, _i, _j;
      result = [[], []];
      for (x = _i = 0; 0 <= BOARD_SIZE ? _i < BOARD_SIZE : _i > BOARD_SIZE; x = 0 <= BOARD_SIZE ? ++_i : --_i) {
        for (y = _j = 0; 0 <= BOARD_SIZE ? _j < BOARD_SIZE : _j > BOARD_SIZE; y = 0 <= BOARD_SIZE ? ++_j : --_j) {
          position = [x, y];
          switch (this.stateAt(position)) {
            case BLACK:
              if (result[0].every(function(g) {
                return g[0].every(function(e) {
                  return !e.isEqualTo(position);
                });
              })) {
                result[0].push(this.stringAndLibertyAt(position));
              }
              break;
            case WHITE:
              if (result[1].every(function(g) {
                return g[0].every(function(e) {
                  return !e.isEqualTo(position);
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

      /* ストリングa, bが接触しているかどうか。 */
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

      /* string(接続した石の集合)の配列からcontact(接続もしくは接触した石の集合)を算出して返す。 */
      var i, j, result, unique, _i, _j, _ref, _ref1, _ref2;
      result = [];
      for (i = _i = 0, _ref = strings.length; 0 <= _ref ? _i < _ref : _i > _ref; i = 0 <= _ref ? ++_i : --_i) {
        if (result[i] == null) {
          result[i] = [strings[i]];
        }
        for (j = _j = _ref1 = i + 1, _ref2 = strings.length; _ref1 <= _ref2 ? _j < _ref2 : _j > _ref2; j = _ref1 <= _ref2 ? ++_j : --_j) {
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
      var adjacencies, gd0, gds, gds0, stone, _i, _len;
      if (checkings == null) {
        checkings = [];
      }

      /*
      座標が眼かどうか調べ、眼ならばどちらの眼かを返し、眼でないならnullを返す。
      眼の定義は、その座標が同一石で囲まれていて、囲んでいる石がその座標以外のダメを詰められないこと。
      checkingsは再帰用引数
      石をかこっている時、2目以上の空点の時、眼と判定しないので改良が必要。
       */
      if (!this.isEmptyAt(position)) {
        return null;
      }
      adjacencies = adjacenciesAt(position);
      if (!(adjacencies.every((function(_this) {
        return function(e) {
          return _this.stateAt(e) === BLACK;
        };
      })(this)) || adjacencies.every((function(_this) {
        return function(e) {
          return _this.stateAt(e) === WHITE;
        };
      })(this)))) {
        return null;
      }
      stone = this.stateAt(adjacencies[0]);
      gds0 = adjacencies.map((function(_this) {
        return function(e) {
          var a;
          return a = _this.stringAndLibertyAt(e);
        };
      })(this));
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
      if (gds.length === 1 || (gds.every((function(_this) {
        return function(gd) {
          var newCheckings;
          newCheckings = checkings.concat([position]);
          return gd[1].filter(function(e) {
            return !e.isEqualTo(position);
          }).some(function(d) {
            return checkings.some(function(e) {
              return d.isEqualTo(e);
            }) || (_this.whoseEyeAt(d, newCheckings) === stone);
          });
        };
      })(this)))) {
        return stone;
      } else {
        return null;
      }
    };

    OnBoard.prototype.eyes = function() {

      /* 眼の座標を返す。１つ目は黒の眼、２つ目は白の眼。 */
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

      /* 座標に置かれた石によって取ることができる相手の石を取り上げて、取り上げた石の座標の配列を返す。 */
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

      /*
      石を座標に着手する。
      着手候補を減らす便宜上、自殺手は着手禁止とする。(中国ルールからの逸脱)
      着手が成立したらtrue。着手禁止の場合false。
      循環手か否かは未チェック。
       */
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


  /*
  シチョウの結論
   */

  EvaluationResult = (function() {
    function EvaluationResult(value, history) {
      this.value = value;
      this.history = history;
    }

    return EvaluationResult;

  })();

  chaser = null;

  escaper = null;

  target = null;

  checkTarget = function(board) {
    var bAtaris, strings, wAtaris;
    strings = board.strings();
    bAtaris = strings[0].filter(function(e) {
      return e[1].length === 1;
    });
    wAtaris = strings[1].filter(function(e) {
      return e[1].length === 1;
    });
    return bAtaris.concat(wAtaris);
  };

  chaseShicho = function(board, targetPosition) {
    var result;
    escaper = board.stateAt(targetPosition);
    chaser = opponentOf(escaper);
    target = targetPosition;
    result = escape([board]);
    return new EvaluationResult(result.value, result.value ? longestSuccess : longestFail);

    /*
    try
        result = escape [board]
        new EvaluationResult result.value, if result.value then longestSuccess else longestFail
    catch e
        console.error e
        alert '頭が爆発しました…'
        new EvaluationResult false, longestFail
     */
  };

  longestFail = [];

  longestSuccess = [];

  escape = function(history) {
    var b, board, candidates, e, p, result, sl, strings, _i, _j, _len, _len1, _ref, _ref1;
    board = history[history.length - 1];
    sl = board.stringAndLibertyAt(target);
    strings = board.strings();
    candidates = [];
    _ref = strings[chaser - 1];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      e = _ref[_i];
      if (e[1].length === 1) {
        candidates.push(e[1][0]);
      }
    }
    candidates.push(sl[1][0]);
    for (_j = 0, _len1 = candidates.length; _j < _len1; _j++) {
      p = candidates[_j];
      b = board.copy();
      if (!b.place(escaper, p) || ((_ref1 = history[history.length - 2]) != null ? _ref1.isEqualTo(b) : void 0)) {
        continue;
      }
      result = chase(history.concat(b));
      if (result.value) {
        if (longestSuccess.length < result.history.length) {
          longestSuccess = result.history;
        }
      } else {
        if (longestFail.length < result.history.length) {
          longestFail = result.history;
        }
        return result;
      }
    }
    result = chase(history.concat(board));
    if (longestSuccess.length < result.history.length) {
      longestSuccess = result.history;
    }
    return result;
  };

  chase = function(history) {
    var b, board, p, result, sl, _i, _len, _ref, _ref1;
    board = history[history.length - 1];
    sl = board.stringAndLibertyAt(target);
    switch (sl[1].length) {
      case 1:
        b = board.copy();
        b.place(chaser, sl[1][0]);
        history.push(b);
        if (longestSuccess.length < history.length) {
          longestSuccess = history;
        }
        return new EvaluationResult(true, history);
      case 2:
        _ref = sl[1];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          p = _ref[_i];
          b = board.copy();
          if (!b.place(chaser, p) || ((_ref1 = history[history.length - 2]) != null ? _ref1.isEqualTo(b) : void 0)) {
            continue;
          }
          result = escape(history.concat(b));
          if (result.value) {
            if (longestSuccess.length < result.history.length) {
              longestSuccess = result.history;
            }
            return result;
          } else {
            if (longestFail.length < result.history.length) {
              longestFail = result.history;
            }
          }
        }
        return new EvaluationResult(false, []);
      default:
        if (longestFail.length < history.length) {
          longestFail = history;
        }
        return new EvaluationResult(false, history);
    }
  };


  /*
  四路の純碁とソルバのクライアント側共通コード
   */

  responseInterval = 2000;

  wEvaluate = function(history, next, success, error, timeout) {
    var timeid, worker;
    if (timeout == null) {
      timeout = 10000;
    }

    /*
    (web workerを使って)局面を評価する。
    
    success, errorはコールバック関数。
     */
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
    if (callback == null) {
      callback = function() {};
    }

    /*
    boardの状態を描画する。
    boardがnullなら空の盤。
    effectをtrueにすると、今の状態からエフェクト入りで盤を変更。
     */
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
    if (effect) {
      return $.when.apply(window, deferredes).done(callback);
    }
  };

  openAndCloseModal = function(id, callback) {
    if (callback == null) {
      callback = function() {};
    }

    /*
    モーダルを一定時間表示する。
     */
    $("#" + id).modal('show');
    return setTimeout((function() {
      $("#" + id).modal('hide');
      return callback();
    }), responseInterval);
  };


  /*
  main for solver.html
   */

  evaluatedResult = null;

  boardOnScreen = function() {
    var blacks, whites;
    blacks = [];
    whites = [];
    $('.intersection').each(function(i, e) {
      var $e;
      $e = $(e);
      if ($e.hasClass('black')) {
        return blacks.push([i % BOARD_SIZE, Math.floor(i / BOARD_SIZE)]);
      } else if ($e.hasClass('white')) {
        return whites.push([i % BOARD_SIZE, Math.floor(i / BOARD_SIZE)]);
      }
    });
    return new OnBoard(blacks, whites);
  };

  editBoard = function() {
    $('#black, #white').removeAttr('disabled');
    return $('.intersection').on('click', function() {
      var $this, stone;
      $this = $(this);
      stone = $('#black-white > .active').attr('id');
      if ($this.hasClass(stone)) {
        return $this.removeClass(stone);
      } else {
        $this.removeClass('black white');
        return $this.addClass(stone);
      }
    });
  };

  stopEditing = function() {
    $('.intersection').off('click');
    return $('#black, #white').attr('disabled', 'disabled');
  };

  scheduleMessage = function() {
    var aux, messages;
    messages = [
      {
        interval: 10000,
        id: 'babble-modal1'
      }, {
        interval: 20000,
        id: 'babble-modal2'
      }, {
        interval: 30000,
        id: 'babble-modal3'
      }, {
        interval: 30000,
        id: 'babble-modal4'
      }
    ];
    aux = function(index) {
      return scheduleMessage.id = setTimeout((function() {
        openAndCloseModal(messages[index].id);
        if (index < messages.length - 1) {
          return aux(index + 1);
        }
      }), messages[index].interval);
    };
    return aux(0);
  };

  cancelMessage = function() {
    return clearTimeout(scheduleMessage.id);
  };

  playSequence = function(history) {
    var aux;
    aux = function(index) {
      return setTimeout((function() {
        if (history[index].isEqualTo(history[index - 1])) {
          openAndCloseModal(index % 2 ? 'black-pass' : 'white-pass');
        } else {
          showOnBoard(history[index], true);
        }
        if (index < history.length - 1) {
          return aux(index + 1);
        } else {
          return $('#sequence').removeAttr('disabled');
        }
      }), 100);
    };
    showOnBoard(history[0]);
    return aux(1);
  };

  $(document.body).on('touchmove', function(e) {
    if (window.Touch) {
      return e.preventDefault();
    }
  });

  $('#reset').on('click', function() {
    return $('.intersection').removeClass('black white');
  });

  startSolve = function(board, target) {
    return openAndCloseModal('start-modal', function() {
      evaluatedResult = chaseShicho(board, target);
      alert(evaluatedResult.value ? "取れました！" : "取れません…");
      $('#sequence').removeAttr('disabled');
      return editBoard();
    });
  };

  $('#solve').on('click', function() {
    var board, ps;
    stopEditing();
    board = boardOnScreen();
    ps = checkTarget(board);
    if (ps.length === 0) {
      alert('アタリの石を作ってください');
      return editBoard();
    } else if (ps.length === 1) {
      return startSolve(board, ps[0][0][0]);
    } else {
      return openAndCloseModal('target-modal', function() {
        return $('.intersection').on('click', function() {
          var index;
          $('.intersection').off('click');
          index = $('.intersection').index(this);
          return startSolve(board, [index % BOARD_SIZE, Math.floor(index / BOARD_SIZE)]);
        });
      });
    }
  });

  $('#sequence').on('click', function() {
    $(this).attr('disabled', 'disabled');
    return playSequence(evaluatedResult.history);
  });

  setBoardSize(19);

  showOnBoard(new OnBoard([[5, 1], [6, 1], [12, 1], [13, 1], [9, 5], [1, 6], [1, 7], [17, 8], [17, 9], [7, 15], [8, 15], [9, 16], [9, 17]], [[5, 0], [6, 0], [12, 0], [13, 0], [9, 2], [0, 5], [8, 5], [18, 5], [0, 6], [18, 6], [0, 7], [18, 7], [0, 8], [18, 8], [0, 9], [18, 9], [9, 14], [9, 15], [8, 16], [8, 17], [10, 17], [9, 18]]));


  /*
   * 浦壁和彦「鬼ごっこ」
  showOnBoard new OnBoard [[1,9],[2,8],[2,9],[2,10],[5,9],[7,9],[8,2],[8,8],[8,18],[9,1],[9,2],[9,5],[9,7],[9,8],[9,16],[9,17],[10,2],[10,16],[11,9],[12,10],[12,13],[12,14],[12,16],[12,17],[13,9],[13,13],[16,8],[16,9],[16,10],[17,9]]
      ,[[0,7],[0,9],[0,11],[1,6],[1,8],[1,10],[1,12],[2,5],[2,13],[3,4],[3,9],[3,14],[4,3],[4,9],[4,15],[5,2],[5,16],[6,1],[6,9],[6,17],[7,0],[7,8],[7,18],[8,1],[8,7],[9,0],[9,3],[9,4],[9,6],[9,9],[10,1],[10,7],[10,8],[10,9],[10,15],[10,17],[11,0],[11,14],[11,16],[11,18],[12,1],[12,11],[12,15],[12,18],[13,2],[13,14],[13,16],[13,17],[14,3],[14,9],[14,15],[15,4],[15,9],[15,14],[16,5],[16,13],[17,6],[17,8],[17,10],[17,12],[18,7],[18,9],[18,11]]
   */

  editBoard();

  $('#opening-modal').modal('show');

}).call(this);
