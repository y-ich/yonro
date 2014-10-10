// Generated by CoffeeScript 1.8.0

/*
碁カーネル
中国ルールを採用。ただし自殺手は着手禁止とする。
 */

(function() {
  var BoardBase, EvaluationResult, boardOnScreen, boardsToString, cancelMessage, chase, chaseShicho, chaser, checkTarget, e, editBoard, escape, escaper, evaluatedResult, longestFail, longestSuccess, openAndCloseModal, playSequence, responseInterval, root, scheduleMessage, showOnBoard, startSolve, stopEditing, target, wEvaluate, _i, _len, _ref;

  Array.prototype.isEqualTo = function(array) {

    /*　配列の要素すべてが等しいか否かを返す。 */
    var e, i, _i, _len;
    if (this.length !== array.length) {
      return false;
    }
    for (i = _i = 0, _len = this.length; _i < _len; i = ++_i) {
      e = this[i];
      if (e !== array[i]) {
        return false;
      }
    }
    return true;
  };

  boardsToString = function(history) {
    return history.map(function(e, i) {
      return "#" + i + "\n" + (e.toString());
    }).join('\n');
  };

  BoardBase = (function() {
    function BoardBase(BOARD_SIZE) {
      this.BOARD_SIZE = BOARD_SIZE;
      this.BLACK = 0;
      this.WHITE = 1;
      this.EMPTY = 2;
      this.MAX_SCORE = this.BOARD_SIZE * this.BOARD_SIZE - 2;
    }

    BoardBase.prototype.opponentOf = function(stone) {

      /* 黒(BLACK)なら白(WHITE)、白(WHITE)なら黒(BLACK)を返す。 */
      switch (stone) {
        case this.BLACK:
          return this.WHITE;
        case this.WHITE:
          return this.BLACK;
        default:
          throw 'error';
      }
    };

    BoardBase.prototype.adjacenciesAt = function(position) {

      /* プライベート */

      /* 隣接する点の座標の配列を返す。 */
      var e, result, x, y, _i, _len, _ref;
      result = [];
      _ref = [[0, -1], [-1, 0], [1, 0], [0, 1]];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        e = _ref[_i];
        x = position[0] + e[0];
        y = position[1] + e[1];
        if ((0 <= x && x < this.BOARD_SIZE) && (0 <= y && y < this.BOARD_SIZE)) {
          result.push([x, y]);
        }
      }
      return result;
    };

    return BoardBase;

  })();

  root = typeof exports !== "undefined" && exports !== null ? exports : typeof window !== "undefined" && window !== null ? window : {};

  _ref = ['BoardBase', 'boardsToString'];
  for (_i = 0, _len = _ref.length; _i < _len; _i++) {
    e = _ref[_i];
    root[e] = eval(e);
  }


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
    var b, board, candidates, p, result, sl, strings, _j, _k, _len1, _len2, _ref1, _ref2;
    board = history[history.length - 1];
    sl = board.stringAndLibertyAt(target);
    strings = board.strings();
    candidates = [];
    _ref1 = strings[chaser - 1];
    for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
      e = _ref1[_j];
      if (e[1].length === 1) {
        candidates.push(e[1][0]);
      }
    }
    candidates.push(sl[1][0]);
    for (_k = 0, _len2 = candidates.length; _k < _len2; _k++) {
      p = candidates[_k];
      b = board.copy();
      if (!b.place(escaper, p) || ((_ref2 = history[history.length - 2]) != null ? _ref2.isEqualTo(b) : void 0)) {
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
    var b, board, p, result, sl, _j, _len1, _ref1, _ref2;
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
        _ref1 = sl[1];
        for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
          p = _ref1[_j];
          b = board.copy();
          if (!b.place(chaser, p) || ((_ref2 = history[history.length - 2]) != null ? _ref2.isEqualTo(b) : void 0)) {
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
      var result;
      $('#evaluating').css('display', 'none');
      clearTimeout(timeid);
      if (event.data.error != null) {
        console.log(event.data.error);
        return error(event.data.error);
      } else {
        result = new EvaluationResult(event.data.value, event.data.history.map(function(e) {
          return OnBoard.fromString(e);
        }));
        console.log(result.toString());
        return success(result);
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
      console.log('timeout');
      return error({
        message: 'timeout'
      });
    }), timeout);
  };

  showOnBoard = function(board, effect, callback) {
    var $intersection, ataris, blacks, deferred, deferredes, p, place, whites, x, y, _j, _k, _ref1, _ref2, _ref3;
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
      $('.intersection').removeClass('black white half-opacity beat');
      return;
    }
    _ref1 = board.deployment(), blacks = _ref1[0], whites = _ref1[1];
    ataris = board.atari();
    deferredes = [];
    for (x = _j = 0, _ref2 = board.base.BOARD_SIZE; 0 <= _ref2 ? _j < _ref2 : _j > _ref2; x = 0 <= _ref2 ? ++_j : --_j) {
      for (y = _k = 0, _ref3 = board.base.BOARD_SIZE; 0 <= _ref3 ? _k < _ref3 : _k > _ref3; y = 0 <= _ref3 ? ++_k : --_k) {
        p = [x, y];
        $intersection = $(".intersection:nth-child(" + (1 + p[0] + p[1] * board.base.BOARD_SIZE) + ")");
        place = function(blackOrWhite, beat) {
          var deferred;
          if (effect && ((!$intersection.hasClass(blackOrWhite)) || ($intersection.hasClass('half-opacity')))) {
            deferred = $.Deferred();
            deferredes.push(deferred);
            $intersection.one($s.vendor.animationend, function() {
              var $this;
              $this = $(this);
              $this.removeClass('shake');
              if (beat) {
                $this.addClass('beat');
              } else {
                $this.removeClass('beat');
              }
              return deferred.resolve();
            });
            return $intersection.removeClass('half-opacity').addClass("" + blackOrWhite + " shake");
          } else {
            $intersection.removeClass('black white half-opacity').addClass(blackOrWhite);
            if (beat) {
              return $intersection.addClass('beat');
            } else {
              return $intersection.removeClass('beat');
            }
          }
        };
        if (blacks.some(function(e) {
          return e.isEqualTo(p);
        })) {
          place('black', ataris.some(function(e) {
            return e.isEqualTo(p);
          }));
        } else if (whites.some(function(e) {
          return e.isEqualTo(p);
        })) {
          place('white', ataris.some(function(e) {
            return e.isEqualTo(p);
          }));
        } else {
          if (effect && ($intersection.hasClass('black') || ($intersection.hasClass('white')))) {
            deferred = $.Deferred();
            deferredes.push(deferred);
            $intersection.removeClass('beat');
            $intersection.one($s.vendor.transitionend, (function(deferred) {
              return function() {
                $(this).removeClass('black white rise');
                return deferred.resolve();
              };
            })(deferred));
            setTimeout((function($intersection) {
              return function() {
                return $intersection.addClass('rise');
              };
            })($intersection), 100);
          } else {
            $intersection.removeClass('white black half-opacity beat');
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
