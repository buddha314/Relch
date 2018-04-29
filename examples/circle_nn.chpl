use NumSuch, Random, Norm;
const nCircles: int = 50,  // of each typ
      radius1: real = 0.6,
      radius2: real = 1.2,
      momentum: real = 0.9,
      learningRate: real = 0.02,
      randomSeed: int = 17;


proc makeCircles(nCircles: int, radius1: real, radius2: real) {
  var   X:[1..2*nCircles, 1..2] real,
        T:[1..2*nCircles, 1..2] real;
  fillRandom(X);
  for i in 1..nCircles {
    X[i,..] = radius1 * X[i, ..];
    X[i+nCircles,..] = radius2 * X[i+nCircles,..];
    T[i,..] = [1.0, 0.0];
    T[i+nCircles, ..] = [0.0, 1.0];

  }
  return (X,T);
}

var X = makeCircles(nCircles, radius1, radius2)[1],
      T = makeCircles(nCircles, radius1, radius2)[2];

proc logistic(z) {
  var x:[z.domain] real;
  x = 1 / (1+exp(-z));
  //writeln("logistic is returning: ", x);
  return x;
}
proc softmax(z:[]) {
  /* Python really plays fast and loose here */
  var v: [z.domain] real,
      c: [1..z.shape(1)] real;
  c = exp(rowSums(z));
  //writeln("softmax c: ", c);
  for i in 1..z.shape(1) {
    v[i,..] = for x in v[i,..] do exp(x) / c[i];
  }
  //writeln("softmax is returning: ", v);
  return v;
}

proc hiddenActivations(X: [], Wh: [], bh: []) {
  var r:[X.domain.dims()(1), Wh.domain.dims()(2)] real = X.dot(Wh) + bh;
  var s:[r.domain] real = logistic(r);
  return s;
}

proc outputActivations(H:[], Wo:[], bo:[]) {
  var r:[H.domain.dims()(1), Wo.domain.dims()(2)] real = H.dot(Wo) + bo;
  return softmax(r);
}

proc nn(X:[], Wh:[], bh: [], Wo:[], bo:[]) {
  var ha = hiddenActivations(X, Wh, bh);
  var oa = outputActivations(ha, Wo, bo);
  //return outputActivations(ha, Wo, bo);
  //writeln("oa: ", oa);
  return oa;
}

proc nnPredict(X:[], Wh:[], bh:[], Wo:[], bo:[]){
  // In the original code this is rounded, will have check that.
  return nn(X, Wh, bh, Wo, bo);
}

proc cost(Y:[], T:[]) {
  //writeln("cost Y: ", Y);
  const x = T * log(Y);
  return -1*(+ reduce x);
}

proc errorOutput(Y:[], T:[]) {
  const r:[Y.domain] real = Y-T;
  return r;
}

proc gradientWeightOut(H:[], Eo:[]) {
  return H.T.dot(Eo);
}

proc gradientBiasOut(Eo:[]) {
  var r:[Eo.domain.dims()(1)] real = colSums(Eo);
  return r;
}

proc errorHidden(H:[], Wo:[], Eo:[]) {
  var r:[H.domain] real = H * (ones(H.domain)-H) * Eo.dot(Wo.T);
  return r;
}

proc gradientWeightHidden(X:[], Eh:[]) {
  return X.T.dot(Eh);
}

proc gradientBiasHidden(Eh:[]) {
  return colSums(Eh);
}

proc backpropGradients(X:[], Wh:[], bh:[], Wo:[], bo:[]) {
  var H = hiddenActivations(X, Wh, bh);
  var Y = outputActivations(H, Wo, bo);
  var Eo = errorOutput(Y, T);
  var JWo = gradientWeightOut(H, Eo);
  var Jbo = gradientBiasOut(Eo);
  var Eh = errorHidden(H, Wo, Eo);
  var JWh = gradientWeightHidden(X, Eh);
  var Jbh = gradientBiasHidden(Eh);
  return (JWh, Jbh, JWo, Jbo);
}

proc updateVelocity(X:[], T:[],
  Wh:[], bh:[], Wo:[], bo:[],
  VWh:[], Vbh:[], VWo:[], Vbo:[],
  momentum:real, learningRate: real) {
    var Js = backpropGradients(X, Wh, bh, Wo, bo),
        JWh = Js[1],
        Jbh = Js[2],
        JWo = Js[3],
        Jbo = Js[4];
    VWh = momentum * VWh - learningRate * JWh;
    Vbh = momentum * Vbh - learningRate * Jbh;
    VWo = momentum * VWo - learningRate * JWo;
    Vbo = momentum * Vbo - learningRate * Jbo;
    //return (VWh, Vbh, VWo, Vbo);  // Chapel passes by reference, no need to return it
    return true;
}

proc updateParams(Wh:[], bh:[], Wo:[], bo:[],
  VWh:[], Vbh:[], VWo:[], Vbo:[]) {
    Wh = Wh + VWh;
    bh = bh + Vbh;
    Wo = Wo + VWo;
    bo = bo + Vbo;
    //return (Wh+VWh, bh+Vbh, Wo+VWo, bo+Vbo );
    return true;
}

const initVar = 0.1;  // scaling factor
var bh: [1..1, 1..3] real,
    Wh: [1..2, 1..3] real,
    bo: [1..1, 1..1] real,
    Wo: [1..3, 1..2] real;
// Chapel needs a few more lines at the moment
fillRandom(bh, randomSeed);
fillRandom(Wh);
fillRandom(bo);
fillRandom(Wo);
bh = initVar * bh;
Wh = initVar * Wh;
bo = initVar * bo;
Wo = initVar * Wo;

var Vbh: [bh.domain] real = 0,
    VWh: [Wh.domain] real = 0,
    Vbo: [bo.domain] real = 0,
    VWo: [Wo.domain] real = 0;

const nIterations: int = 30;
var lrUpdate = learningRate / nIterations,  // Is not used in original code
    lsCosts: [1..0] real;

lsCosts.push_back(cost(nn(X, Wh, bh, Wo, bo), T));

for i in 1..nIterations {
  writeln("starting iter ", i);
  var Vs = updateVelocity(X=X, T=T, Wh=Wh, bh=bh, Wo=Wo, bo=bo,
    VWh=VWh, Vbh=Vbh, VWo=VWo, Vbo=Vbo,
    momentum=momentum, learningRate=learningRate);
  var Ps = updateParams(Wh=Wh, bh=bh, Wo=Wo, bo=bo,
    VWh=VWh, Vbh=Vbh, VWo=VWo, Vbo=Vbo);
  lsCosts.push_back(cost(nn(X, Wh, bh, Wo, bo), T));
  printNorms(X, Wh, bh, Wo, bo);
}
writeln("\n\n Costs: ", lsCosts);

/*
  Check to see who is exploding
 */
proc printNorms(X:[], Wh:[], bh:[], Wo:[], bo:[]) {
  try! writeln(" Norms: X: %7.4dr   Wh: %7.4dr,   bh: %7.4dr   Wo: %7.4dr   bo: %7.4dr"
    .format(norm(X), norm(Wh), norm(bh), norm(Wo), norm(bo)));
}
