// Generated by CoffeeScript 1.7.1

/*
碁カーネル
中国ルールを採用。ただし自殺手は着手禁止とする。
 */

(function() {
  var BLACK, BOARD_SIZE, EMPTY, EvaluationResult, MAX_SCORE, OnBoard, WHITE, adjacenciesAt, compare, evalUntilDepth, evaluate, opponentOf, setBoardSize;

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
            }) || (function(c) {
              return _this.whoseEyeAt(d, c) === stone;
            })(newCheckings);
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
  局面評価
  中国ルールを採用。ただし自殺手は着手禁止とする。
   */

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

    /*
    historyの最終局面の評価値と評価値に至る手順を返す。
    nextは次の手番。
    passは直前、その前の手がパスだったかを示す。(局面比較の演算を省略するため)
    depthは最大深度。反復進化パラメータ
    alpha, betaはαβ枝狩りパラメータ
     */
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
          return -compare(a, b, next);
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
          return -compare(a, b, next);
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

  self.onmessage = function(event) {
    var error, history, result, _ref, _ref1;
    try {
      history = event.data.history.map(function(e) {
        return OnBoard.fromString(e);
      });
      if ((_ref = history[history.length - 2]) != null ? _ref.isEqualTo(history[history.length - 1]) : void 0) {
        history[history.length - 2] = history[history.length - 1];
        if ((_ref1 = history[history.length - 3]) != null ? _ref1.isEqualTo(history[history.length - 1]) : void 0) {
          history[history.length - 3] = history[history.length - 1];
        }
      }
      if (event.data.size != null) {
        setBoardSize(event.data.size);
      }
      result = evaluate(history, event.data.next);
      event.data.value = result.value;
      return event.data.history = result.history.map(function(e) {
        return e.toString();
      });
    } catch (_error) {
      error = _error;
      return event.data.error = {
        line: error.line,
        message: error.message,
        sourceURL: error.sourceURL,
        stack: error.stack
      };
    } finally {
      postMessage(event.data);
      close();
    }
  };

}).call(this);
