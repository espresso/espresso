module ECoreTest__Automount

  class Accept < E
    map :accepted
  end
  class Reject < E
    map :rejected
    reject_automount!
  end

  Spec.new self do
    app E.new(ECoreTest__Automount)

    get :accepted
    is(last_response).ok?
    get :rejected
    is(last_response).not_found?
  end

  Spec.new self do
    app E.new(/Test__Automount/)

    get :accepted
    is(last_response).ok?
    get :rejected
    is(last_response).not_found?
  end

end
