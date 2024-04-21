// See: https://github.com/jquery/jquery-ui/pull/1822#issuecomment-339250888

DatepickerProtoType = $.datepicker.constructor.prototype

DatepickerProtoType._setDateDatepicker = function(target, date) {
    var inst = this._getInst(target);

    if (inst) {
        this._setDate(inst, date);

        if ($.datepicker._datepickerShowing === true) {
            if (inst === $.datepicker._curInst) {
                // If a datepicker is already showing, set it to date only if it belongs
                // to the current target

                this._updateDatepicker(inst);
            }
        } else {
            this._updateDatepicker(inst);
        }

        this._updateAlternate(inst);
    }
};