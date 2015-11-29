# -*- coding: utf-8 -*-
# distutils: language = c++
# distutils: libraries = gmp mpfr fplll

include "interrupt/interrupt.pxi"

from qd.qd cimport dd_real, qd_real
from gmp.mpz cimport mpz_t
from mpfr.mpfr cimport mpfr_t
from integer_matrix cimport IntegerMatrix

from fplll cimport LLL_VERBOSE
from fplll cimport LLL_EARLY_RED
from fplll cimport LLL_SIEGEL
from fplll cimport LLL_DEFAULT

from fplll cimport LLLMethod, LLL_DEF_ETA, LLL_DEF_DELTA
from fplll cimport LM_WRAPPER, LM_PROVED, LM_HEURISTIC, LM_FAST
from fplll cimport FT_DEFAULT, FT_DOUBLE, FT_LONG_DOUBLE, FT_DD, FT_QD

from fplll cimport Z_NR, FP_NR
from fplll cimport lllReduction as lllReduction_c
from fplll cimport RED_SUCCESS
from fplll cimport MatGSO as MatGSO_c
from fplll cimport LLLReduction as LLLReduction_c
from fplll cimport getRedStatusStr
from fplll cimport isLLLReduced

from util cimport check_float_type, check_delta, check_eta, check_precision
from fpylll import ReductionError
from fpylll cimport mpz_double, mpz_dd, mpz_qd, mpz_mpfr

from wrapper import Wrapper

cdef class LLLReduction:
    def __init__(self, MatGSO M,
                 double delta=LLL_DEF_DELTA,
                 double eta=LLL_DEF_ETA,
                 int flags=LLL_DEFAULT):
        """FIXME!  briefly describe function

        :param MatGSO M:
        :param double delta:
        :param double eta:
        :param int flags:

            - ``DEFAULT``:

            - ``VERBOSE``:

            - ``EARLY_RED``:

            - ``SIEGEL``:

        """

        check_delta(delta)
        check_eta(eta)

        cdef MatGSO_c[Z_NR[mpz_t], FP_NR[double]]  *m_double
        cdef MatGSO_c[Z_NR[mpz_t], FP_NR[dd_real]] *m_dd
        cdef MatGSO_c[Z_NR[mpz_t], FP_NR[qd_real]] *m_qd
        cdef MatGSO_c[Z_NR[mpz_t], FP_NR[mpfr_t]]  *m_mpfr

        self.m = M

        if M._type == mpz_double:
            m_double = M._core.mpz_double
            self._type = mpz_double
            self._core.mpz_double = new LLLReduction_c[Z_NR[mpz_t], FP_NR[double]](m_double[0],
                                                                                   delta,
                                                                                   eta, flags)
        elif M._type == mpz_dd:
            m_dd = M._core.mpz_dd
            self._type = mpz_dd
            self._core.mpz_dd = new LLLReduction_c[Z_NR[mpz_t], FP_NR[dd_real]](m_dd[0],
                                                                                delta,
                                                                                eta, flags)
        elif M._type == mpz_qd:
            m_qd = M._core.mpz_qd
            self._type = mpz_qd
            self._core.mpz_qd = new LLLReduction_c[Z_NR[mpz_t], FP_NR[qd_real]](m_qd[0],
                                                                                delta,
                                                                                eta, flags)
        elif M._type == mpz_mpfr:
            m_mpfr = M._core.mpz_mpfr
            self._type = mpz_mpfr
            self._core.mpz_mpfr = new LLLReduction_c[Z_NR[mpz_t], FP_NR[mpfr_t]](m_mpfr[0],
                                                                                 delta,
                                                                                 eta, flags)
        else:
            raise RuntimeError("MatGSO object '%s' has no core."%self)

        self._delta = delta
        self._eta = eta

    def __dealloc__(self):
        if self._type == mpz_double:
            del self._core.mpz_double
        if self._type == mpz_dd:
            del self._core.mpz_dd
        if self._type == mpz_qd:
            del self._core.mpz_qd
        if self._type == mpz_mpfr:
            del self._core.mpz_mpfr

    def __call__(self, int kappa_min=0, int kappa_start=0, int kappa_end=-1):
        """FIXME! briefly describe function

        :param int kappa_min:
        :param int kappa_start:
        :param int kappa_end:
        :returns:
        :rtype:

        """
        if self.m.d == 0:
            return

        cdef int r
        if self._type == mpz_double:
            sig_on()
            self._core.mpz_double.lll(kappa_min, kappa_start, kappa_end)
            r = self._core.mpz_double.status
            sig_off()
        elif self._type == mpz_dd:
            sig_on()
            self._core.mpz_dd.lll(kappa_min, kappa_start, kappa_end)
            r = self._core.mpz_dd.status
            sig_off()
        elif self._type == mpz_qd:
            sig_on()
            self._core.mpz_qd.lll(kappa_min, kappa_start, kappa_end)
            r = self._core.mpz_qd.status
            sig_off()
        elif self._type == mpz_mpfr:
            sig_on()
            self._core.mpz_mpfr.lll(kappa_min, kappa_start, kappa_end)
            r = self._core.mpz_mpfr.status
            sig_off()
        else:
            raise RuntimeError("LLLReduction object '%s' has no core."%self)

        if r:
            raise ReductionError( str(getRedStatusStr(r)) )

    def size_reduction(self, int kappa_min=0, int kappa_end=-1):
        """FIXME! briefly describe function

        :param int kappa_min:
        :param int kappa_end:

        """
        if self._type == mpz_double:
            r = self._core.mpz_double.sizeReduction(kappa_min, kappa_end)
        elif self._type == mpz_dd:
            r = self._core.mpz_dd.sizeReduction(kappa_min, kappa_end)
        elif self._type == mpz_qd:
            r = self._core.mpz_qd.sizeReduction(kappa_min, kappa_end)
        elif self._type == mpz_mpfr:
            r = self._core.mpz_mpfr.sizeReduction(kappa_min, kappa_end)
        else:
            raise RuntimeError("LLLReduction object '%s' has no core."%self)
        if not r:
            raise ReductionError( str(getRedStatusStr(r)) )

    @property
    def final_kappa(self):
        """FIXME! briefly describe function

        :returns:
        :rtype:

        """
        if self._type == mpz_double:
            return self._core.mpz_double.finalKappa
        elif self._type == mpz_dd:
            return self._core.mpz_dd.finalKappa
        elif self._type == mpz_qd:
            return self._core.mpz_qd.finalKappa
        elif self._type == mpz_mpfr:
            return self._core.mpz_mpfr.finalKappa
        else:
            raise RuntimeError("LLLReduction object '%s' has no core."%self)

    @property
    def last_early_red(self):
        """FIXME! briefly describe function

        :returns:
        :rtype:

        """
        if self._type == mpz_double:
            return self._core.mpz_double.lastEarlyRed
        elif self._type == mpz_dd:
            return self._core.mpz_dd.lastEarlyRed
        elif self._type == mpz_qd:
            return self._core.mpz_qd.lastEarlyRed
        elif self._type == mpz_mpfr:
            return self._core.mpz_mpfr.lastEarlyRed
        else:
            raise RuntimeError("LLLReduction object '%s' has no core."%self)

    @property
    def zeros(self):
        """FIXME! briefly describe function

        :returns:
        :rtype:

        """
        if self._type == mpz_double:
            return self._core.mpz_double.zeros
        elif self._type == mpz_dd:
            return self._core.mpz_dd.zeros
        elif self._type == mpz_qd:
            return self._core.mpz_qd.zeros
        elif self._type == mpz_mpfr:
            return self._core.mpz_mpfr.zeros
        else:
            raise RuntimeError("LLLReduction object '%s' has no core."%self)

    @property
    def nswaps(self):
        """FIXME! briefly describe function

        :returns:
        :rtype:

        """
        if self._type == mpz_double:
            return self._core.mpz_double.nSwaps
        elif self._type == mpz_dd:
            return self._core.mpz_dd.nSwaps
        elif self._type == mpz_qd:
            return self._core.mpz_qd.nSwaps
        elif self._type == mpz_mpfr:
            return self._core.mpz_mpfr.nSwaps
        else:
            raise RuntimeError("LLLReduction object '%s' has no core."%self)

    @property
    def delta(self):
        return self._delta

    @property
    def eta(self):
        return self._eta


def lll_reduction(IntegerMatrix B, U=None,
                  double delta=LLL_DEF_DELTA, double eta=LLL_DEF_ETA,
                  method=None, float_type=None,
                  int precision=0, int flags=LLL_DEFAULT):
    """FIXME! briefly describe function

    :param IntegerMatrix B:
    :param U:
    :param double delta:
    :param double eta:
    :param method:
    :param float_type:
    :param int precision:
    :param int flags:
    :returns:
    :rtype:

    """

    check_delta(delta)
    check_eta(eta)
    check_precision(precision)

    cdef LLLMethod method_
    if method == "wrapper" or method is None:
        method_ = LM_WRAPPER
    elif method == "proved":
        method_ = LM_PROVED
    elif method == "heuristic":
        method_ = LM_HEURISTIC
    elif method == "fast":
        method_ = LM_FAST
    else:
        raise ValueError("Method '%s' unknown."%method)

    if float_type is None and method_ == LM_FAST:
        float_type = "double"

    if method_ == LM_WRAPPER and check_float_type(float_type) != FT_DEFAULT:
        raise ValueError("LLL wrapper function requires float_type==None")

    if method_ == LM_FAST and \
       check_float_type(float_type) not in (FT_DOUBLE, FT_LONG_DOUBLE, FT_DD, FT_QD):
        raise ValueError("LLL fast function requires "
                         "float_type == 'double' or 'long double'")

    cdef int r

    if U is not None and isinstance(U, IntegerMatrix):
        sig_on()
        r = lllReduction_c(B._core[0], (<IntegerMatrix>U)._core[0],
                           delta, eta, method_,
                           check_float_type(float_type), precision, flags)
        sig_off()

    else:
        sig_on()
        r = lllReduction_c(B._core[0],
                           delta, eta, method_,
                           check_float_type(float_type), precision, flags)
        sig_off()

    if r:
        raise ReductionError( str(getRedStatusStr(r)) )


def is_LLL_reduced(M, delta=LLL_DEF_DELTA, eta=LLL_DEF_ETA):
    """Test if ``M`` is LLL reduced.

    :param M: either an GSO object of an integer matrix or an integer matrix.
    :param delta: LLL parameter δ < 1
    :param eta: LLL parameter η > 0.5

    :returns: Return ``True`` if ``M`` is definitely LLL reduced, ``False`` otherwise.

    Random matrices are typically not LLL reduced::

        >>> from fpylll import IntegerMatrix, LLL
        >>> A = IntegerMatrix(40, 40)
        >>> A.randomize('uniform', bits=32)
        >>> LLL.is_reduced(A)
        False

    LLL reduction should produce matrices which are LLL reduced::

        >>> LLL.reduction(A)
        >>> LLL.is_reduced(A)
        True

    ..  note:: This function may return ``False`` for LLL reduced matrices if the precision used
        to compute the GSO is too small.
    """
    check_delta(delta)
    check_eta(eta)

    cdef MatGSO M_

    if isinstance(M, MatGSO):
        M_ = M
    elif isinstance(M, IntegerMatrix):
        M_ = MatGSO(M)
        M_.update_gso()
    else:
        raise TypeError("Type '%s' not understood."%type(M))

    if M_._type == mpz_double:
        r = isLLLReduced[Z_NR[mpz_t], FP_NR[double]](M_._core.mpz_double[0], delta, eta)
    elif M_._type == mpz_dd:
        r = isLLLReduced[Z_NR[mpz_t], FP_NR[dd_real]](M_._core.mpz_dd[0], delta, eta)
    elif M_._type == mpz_qd:
        r = isLLLReduced[Z_NR[mpz_t], FP_NR[qd_real]](M_._core.mpz_qd[0], delta, eta)
    elif M_._type == mpz_mpfr:
        r = isLLLReduced[Z_NR[mpz_t], FP_NR[mpfr_t]](M_._core.mpz_mpfr[0], delta, eta)
    else:
        raise RuntimeError("MatGSO object '%s' has no core."%M)

    return bool(r)

class LLL:
    DEFAULT = LLL_DEFAULT
    VERBOSE = LLL_VERBOSE
    EARLY_RED = LLL_EARLY_RED
    SIEGEL = LLL_SIEGEL
    Reduction = LLLReduction
    reduction = lll_reduction
    is_reduced = is_LLL_reduced

    Wrapper = Wrapper